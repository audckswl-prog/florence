import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_promotion_model.dart';

class AIPromotionRepository {
  final SupabaseClient _supabase;
  late final GenerativeModel _model;

  AIPromotionRepository(this._supabase) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Warning: GEMINI_API_KEY is not set in .env');
    }
    
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey ?? '',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<AIPromotionModel?> getPromotion(String isbn, String title, String author, String description) async {
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

      // 2. Not found, generate using Gemini API
      debugPrint('No cache found. Generating AI promotion for $isbn...');
      
      final prompt = """
너는 세계 최고의 베스트셀러 편집자이자 매혹적인 스토리텔러야. 
네 목표는 독자가 이 책을 당장 읽지 않고는 못 배기게 만드는 흥미로운 백그라운드 스토리를 들려주는 거야.

[책 정보]
- 제목: $title
- 저자: $author
- 책 소개: $description

[작성 규칙]
2. [책의 시대와 장르에 따른 맞춤형 분석 지시]
   - A. '고전문학' 혹은 '과거 역사/명저'인 경우: 저자가 이 책을 집필할 당시의 시대적 배경, 그 시대의 사상, 흥미로운 비하인드 스토리를 집중적으로 다뤄줘. 그리고 과거의 그 사상이 지금 현대 사회를 살아가는 우리가 겪는 실제 이슈나 일상과 어떻게 이어지는지 짚어줘.
   - B. '최근 출간된 신간, 경제/경영, IT/과학, 실용서'인 경우: 절대 억지로 과거의 '시대적 배경'을 지어내지 마. 어색하게 과거 사회를 논하지 말고, 제공된 [책 소개] 데이터를 100% 활용해서 이 책이 다루고 있는 '현대 사회의 최신 트렌드'나 '현실적인 문제'를 날카롭게 관통해 줘. 독자가 당장 현실에서 이 책으로 어떻게 위기를 대비하고 인사이트를 얻을지 카피라이터처럼 강렬하게 분석해.
3. 만약 책 제목에 '1권', '2권' 등 시리즈물의 특정 권수가 포함되어 있다면, 전체 작품을 관통하는 분석을 하되, 독자가 이 특정 권수를 읽으며 기대할 수 있는 전개나 긴장감을 자연스럽게 녹여줘.
4. 분량은 전체 글자 수 기준 700~800자 내외의 충분히 깊이있는 2~3문단으로 써. 분량이 너무 짧으면 안 돼.
5. 전문성과 구체성을 단단하게 유지하되, 전문 지식이 전혀 없는 독자도 단숨에 이해하고 엄청난 흥미를 느끼게 유튜브 리뷰 채널처럼 아주 쉽고 흡입력 있는 일상 언어로 풀어써.
6. 마지막 문장은 반드시 독자에게 이 책에서 무엇을 얻어갈 수 있을지 강렬한 호기심을 던지는 문장(예: '당신이라면 이 거대한 운명 앞에서 어떤 선택을 하시겠습니까?' 혹은 '당신의 지갑을 노리는 보이지 않는 손, 지금 당신은 안전하십니까?')으로 마무리해.
7. 대답은 반드시 아래 JSON 형식으로만 해. 다른 말은 절대 덧붙이지 마.

{
  "hook_title": "시선을 끄는 단 한 줄의 강력한 소제목",
  "historical_background": "맞춤형 분석 내용 (고전은 시대배경과 현대의 연결 / 신작실용서는 최신 트렌드와 현실적 통찰) (흡입력 있는 2~3문단, 700~800자 내외)",
  "closing_question": "독자를 유혹하는 마지막 호기심 유발 질문 (1문단)"
}
""";

      final content = [Content.text(prompt)];
      final aiResponse = await _model.generateContent(content);
      
      if (aiResponse.text == null) {
        throw Exception('AI returned empty response');
      }

      // Parse JSON from Gemini
      String jsonString = aiResponse.text!;
      // Clean up markdown quotes if Gemini wrapped the JSON
      jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
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
        historicalBackground: decodeHtmlEntities(jsonMap['historical_background'] ?? ''),
        closingQuestion: decodeHtmlEntities(jsonMap['closing_question'] ?? ''),
      );

      // 3. Save to Supabase for future use
      await _supabase.from('book_promotions').insert(newPromotion.toJson());

      return newPromotion;
    } catch (e) {
      debugPrint('Error getting AI promotion: $e');
      return null;
    }
  }
}
