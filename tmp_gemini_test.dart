import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyBzodFFjZxbPmhCWIA954QFMR4w8mCmOkQ';
  const modelName = 'gemini-2.5-flash';

  final prompt = 'Tell me a story about Florence in json format {"hook_title": "test", "historical_background": "test", "closing_question": "test"}';

  final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/' + modelName + ':generateContent?key=' + apiKey);

  for (int i = 1; i <= 5; i++) {
    print('--- Attempt ' + i.toString() + ' ---');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "responseMimeType": "application/json"
          }
        }),
      );

      if (response.statusCode == 200) {
        print('Success ' + i.toString());
      } else {
        print('Error ' + i.toString() + ': ' + response.statusCode.toString() + ' - ' + response.body);
      }
    } catch (e) {
      print('Exception ' + i.toString() + ': ' + e.toString());
    }
    await Future.delayed(Duration(seconds: 4)); // Delay 4 seconds to simulate user reading
  }
}
