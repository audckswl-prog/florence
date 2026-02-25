import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import '../../core/constants/api_constants.dart';

class AladinService {
  final String ttbKey;
  static const String baseUrl = 'https://www.aladin.co.kr/ttb/api';

  AladinService({required this.ttbKey});

  Future<List<Book>> searchBook(String query) async {
    String urlStr = '$baseUrl/ItemSearch.aspx?ttbkey=$ttbKey&Query=$query&QueryType=Title&MaxResults=10&start=1&SearchTarget=Book&Output=js&Version=20131101&OptResult=subInfo';
    
    if (kIsWeb) {
      // Use corsproxy.io for better stability
      urlStr = 'https://corsproxy.io/?${Uri.encodeComponent(urlStr)}';
    }

    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = data['item'] ?? [];
        return items.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      throw Exception('Error searching books: $e');
    }
  }

  Future<Book?> getBookDetail(String isbn) async {
     String urlStr = '$baseUrl/ItemLookUp.aspx?ttbkey=$ttbKey&ItemId=$isbn&ItemIdType=ISBN13&Output=js&Version=20131101';

     if (kIsWeb) {
       urlStr = 'https://corsproxy.io/?${Uri.encodeComponent(urlStr)}';
     }

     final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = data['item'] ?? [];
        if (items.isNotEmpty) {
           return Book.fromJson(items.first);
        }
        return null;
        
      } else {
         throw Exception('Failed to load book detail');
      }
    } catch (e) {
      throw Exception('Error getting book details: $e');
    }
  }
}
