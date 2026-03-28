import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const ttbKey = 'ttbaudckswl1513001';
  const query = '군주의 거울';
  const baseUrl = 'https://www.aladin.co.kr/ttb/api/ItemSearch.aspx';

  final encodedQuery = Uri.encodeComponent(query);
  final urlStr = '$baseUrl?ttbkey=$ttbKey&Query=$encodedQuery&QueryType=Keyword&MaxResults=30&start=1&SearchTarget=Book&Output=js&Version=20131101';
  final url = Uri.parse(urlStr);

  try {
    print('--- Testing Keyword & MaxResults 30 ---');
    final res = await http.get(url);
    final data = jsonDecode(res.body);
    final items = data['item'] as List<dynamic>? ?? [];
    print('Count: ${items.length}');
    for (var i = 0; i < items.length; i++) {
        print('[${i+1}] ${items[i]['title']} (${items[i]['author']})');
    }
  } catch (e) {
    print('Error: $e');
  }
}
