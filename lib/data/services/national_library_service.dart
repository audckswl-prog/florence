import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NationalLibraryService {
  final String certKey;
  static const String baseUrl = 'https://www.nl.go.kr/seoji/SearchApi.do';

  NationalLibraryService({required this.certKey});

  /// ISBN 번호로 국립중앙도서관 서지정보에서 페이지 수(쪽수)를 조회합니다.
  Future<int?> getPageCount(String isbn) async {
    final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (cleanIsbn.isEmpty) return null;

    final trimmedKey = certKey.trim();
    if (trimmedKey.isEmpty) {
      // 국립도서관 인증키가 아직 입력되지 않은 상태에서는 조용히 스킵
      return null;
    }

    final urlStr =
        '$baseUrl?cert_key=$trimmedKey&result_style=json&page_no=1&page_size=1&isbn=$cleanIsbn';

    try {
      final response = await http
          .get(Uri.parse(urlStr))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final docs = data['docs'] as List<dynamic>?;
        if (docs != null && docs.isNotEmpty) {
          final first = docs.first;
          final pageRaw = first['PAGE']?.toString() ?? '';
          // 예: "324 p.", "324쪽", "324" 등에서 숫자만 추출
          final match = RegExp(r'\d+').firstMatch(pageRaw);
          if (match != null) {
            return int.tryParse(match.group(0)!);
          }
        }
      }
    } catch (e) {
      debugPrint('NationalLibrary pageCount lookup skipped/failed: $e');
    }
    return null;
  }
}
