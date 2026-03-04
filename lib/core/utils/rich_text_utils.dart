import 'dart:convert';

class RichTextUtils {
  /// Extracts plain text from a Quill Delta JSON string.
  /// If the string is not valid JSON, returns the original string.
  static String extractPlainText(String jsonStr) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final buffer = StringBuffer();

      for (var element in jsonList) {
        if (element is Map<String, dynamic> && element.containsKey('insert')) {
          final insert = element['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      // Return as is for legacy plain-text memos
      return jsonStr.trim();
    }
  }
}
