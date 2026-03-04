import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_ticket_model.dart';

class AITicketRepository {
  final SupabaseClient _supabase;
  late final GenerativeModel _model;

  AITicketRepository(this._supabase) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Warning: GEMINI_API_KEY is not set in .env');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey ?? '',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<AITicketModel> getTicketMetadata(
    String isbn,
    String title,
    String author,
  ) async {
    try {
      // 1. Check cache in Supabase first (if we decide to cache ticket data like promotions)
      // For now, let's keep it simple and just fetch from Gemini. Or create a new table 'book_tickets'?
      // Since creating a new table requires SQL schema updates which might be slow,
      // let's just use Gemini directly for now and cache locally in memory or rely on the fast response,
      // or we can reuse `book_promotions` table by adding columns? Let's just call Gemini directly first.

      debugPrint('Generating AI ticket metadata for $isbn...');

      final prompt =
          """
너는 전세계 출판 데이터를 알고 있는 도서 전문가야. 
주어진 책의 원저자가 속한 국적과, 책이 처음 출간된 연도를 알려줘.

[책 정보]
- 제목: $title
- 저자: $author

[작성 규칙]
1. 국가는 저자의 국적을 기준으로 해. (예: 마이클 샌델 -> 미국, 플라톤 -> 그리스). 정확한 국가를 모른다면 출간된 도시나 나라 등 가장 관련 깊은 지역을 적어줘.
2. 'nationality_code'에는 해당 국가의 ISO 3166-1 alpha-2 코드(2자리 영문자)를 넣어줘. (예: US, KR, GB, GR). 이를 기반으로 이모지 국기를 렌더링할 거야.
3. 'nationality_name'에는 한국어로 국가 이름 표기를 짧게 해줘. (예: 미국, 대한민국, 영국)
4. 'publication_year'에는 최초 출간 연도를 'YYYY년' 형식으로 적어줘. (기원전일 경우 '기원전 ~년' 또는 'BC ~년')
5. 대답은 반드시 아래 JSON 형식으로만 해. 다른 말은 절대 덧붙이지 마.

{
  "nationality_code": "US",
  "nationality_name": "미국",
  "publication_year": "2009년"
}
""";

      final content = [Content.text(prompt)];
      final aiResponse = await _model.generateContent(content);

      if (aiResponse.text == null) {
        throw Exception('AI returned empty response');
      }

      String jsonString = aiResponse.text!;
      jsonString = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      final ticketData = AITicketModel(
        isbn: isbn,
        nationalityCode:
            jsonMap['nationality_code']?.toString().toUpperCase() ?? 'UN',
        nationalityName: jsonMap['nationality_name'] ?? '알 수 없음',
        publicationYear: jsonMap['publication_year'] ?? '연도 미상',
      );

      return ticketData;
    } catch (e) {
      debugPrint('Error getting AI ticket metadata: $e');
      // Fallback in case of error
      return AITicketModel(
        isbn: isbn,
        nationalityCode: 'UN',
        nationalityName: '국가 미상',
        publicationYear: '연도 미상',
      );
    }
  }
}
