import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('.env');
  if (!await file.exists()) {
    print('No .env file found');
    return;
  }
  
  final lines = await file.readAsLines();
  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.substring('GEMINI_API_KEY='.length).trim();
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('API key not found in .env');
    return;
  }

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(url);
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final models = data['models'] as List;
      print('=== Available Models for generateContent ===');
      for (var model in models) {
        final methods = model['supportedGenerationMethods'] as List?;
        if (methods != null && methods.contains('generateContent')) {
           final name = model['name'];
           // name is something like 'models/gemini-1.5-flash'
           print(name);
        }
      }
    } else {
      print('Error: ${response.statusCode}\n$responseBody');
    }
    client.close();
  } catch (e) {
    print('Exception: $e');
  }
}
