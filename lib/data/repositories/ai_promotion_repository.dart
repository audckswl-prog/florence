import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_promotion_model.dart';

class AIPromotionRepository {
  final SupabaseClient _supabase;

  AIPromotionRepository(this._supabase);

  Future<AIPromotionModel?> getPromotion(
    String isbn,
    String title,
    String author,
    String description,
  ) async {
    try {
      // 1. Check cache in Supabase first
      final response = await _supabase
          .from('book_promotions')
          .select()
          .eq('isbn', isbn)
          .maybeSingle();

      if (response != null) {
        debugPrint('Found cached AI promotion for $isbn');
        return AIPromotionModel.fromJson(response);
      }

      // 2. Not found, generate using Gemini API via Supabase Edge Function
      debugPrint('No cache found. Generating AI promotion for $isbn via Edge Function...');

      FunctionResponse? aiResponse;
      const maxRetries = 3;
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          aiResponse = await _supabase.functions.invoke(
            'chat-with-gemini',
            body: {
              'title': title,
              'author': author,
              'description': description,
            },
          );
          if (aiResponse.status == 200) break; // 성공 시 루프 탈출
        } catch (retryError) {
          if (attempt == maxRetries) {
            debugPrint('❌ [Florence Docent] $maxRetries회 재시도 후에도 실패: $retryError');
            rethrow;
          }
          final waitSeconds = 1 << attempt; // 1, 2, 4초
          debugPrint('⚠️ [Florence Docent] 시도 ${attempt + 1} 실패, $waitSeconds초 후 재시도... ($retryError)');
          await Future.delayed(Duration(seconds: waitSeconds));
        }
      }

      if (aiResponse?.status != 200 || aiResponse?.data == null) {
        throw Exception('Edge Function returned error: ${aiResponse?.status} - ${aiResponse?.data}');
      }

      // Parse JSON from Edge Function response
      Map<String, dynamic> jsonMap;
      if (aiResponse!.data is Map) {
        jsonMap = aiResponse.data as Map<String, dynamic>;
      } else if (aiResponse.data is String) {
        jsonMap = jsonDecode(aiResponse.data as String) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected response format: ${aiResponse.data}');
      }

      // Helper to clean up HTML entities Gemini might return
      String decodeHtmlEntities(String text) {
        return text
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'");
      }

      final newPromotion = AIPromotionModel(
        isbn: isbn,
        hookTitle: decodeHtmlEntities(jsonMap['hook_title'] ?? '피렌체 맞춤형 책 소개'),
        historicalBackground: decodeHtmlEntities(
          jsonMap['historical_background'] ?? '',
        ),
        closingQuestion: decodeHtmlEntities(jsonMap['closing_question'] ?? ''),
      );

      // 3. Save to Supabase for future use
      try {
        await _supabase.from('book_promotions').upsert(newPromotion.toJson());
      } catch (dbError) {
        debugPrint('Warning: Failed to cache promotion in Supabase (Non-fatal): $dbError');
      }

      return newPromotion;
    } catch (e) {
      debugPrint('Error getting AI promotion: $e');
      return AIPromotionModel(
        isbn: isbn,
        hookTitle: '에러 발생 알림',
        historicalBackground: '데이터베이스나 API 연동 과정에서 문제가 발생했습니다:\n$e',
        closingQuestion: '해결이 필요합니다.',
      );
    }
  }
}
