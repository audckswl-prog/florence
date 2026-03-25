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

  /// Extracts plain text from a Quill Delta JSON string and strips out the legacy
  /// hardcoded date format ("yyyy. M. d. a h:m") if it appears at the very beginning.
  static String extractPlainTextWithoutDate(String jsonStr) {
    String plainText = extractPlainText(jsonStr);

    // Regular Expression to match legacy date format at the start
    // Matches: "2026. 2. 21. 오후 10:1" or similar variants including linebreaks.
    final RegExp datePattern = RegExp(
      r'^\d{4}\.\s?\d{1,2}\.\s?\d{1,2}\.\s?(오전|오후)\s?\d{1,2}:\d{1,2}\s*',
    );

    return plainText.replaceAll(datePattern, '').trim();
  }
}
