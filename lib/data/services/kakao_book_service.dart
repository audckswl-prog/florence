import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class KakaoBookService {
  final String restApiKey;
  static const String baseUrl = 'https://dapi.kakao.com/v3/search/book';

  KakaoBookService({required this.restApiKey});

  Future<List<Book>> searchBook(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(trimmedQuery);
    final urlStr = '$baseUrl?query=$encodedQuery&size=30&page=1';
    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'KakaoAK $restApiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> documents = data['documents'] ?? [];
        return documents.map((json) => Book.fromKakaoJson(json)).toList();
      } else {
        debugPrint(
            'Kakao book search failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load books from Kakao');
      }
    } catch (e) {
      debugPrint('Error searching books via Kakao: $e');
      rethrow;
    }
  }

  Future<Book?> getBookByIsbn(String isbn) async {
    final cleanIsbn = isbn.trim();
    if (cleanIsbn.isEmpty) return null;

    final books = await searchBook(cleanIsbn);
    if (books.isNotEmpty) {
      return books.first;
    }
    return null;
  }
}
