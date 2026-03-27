import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

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
    print('API Key not found');
    return;
  }

  print('Testing gemini-2.5-flash with package...');
  try {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
    final aiResponse = await model.generateContent([Content.text('{"test": "hello"} Return this in json')]);
    print('SUCCESS! Response: ${aiResponse.text}');
  } catch (e) {
    print('ERROR: $e');
  }
}
