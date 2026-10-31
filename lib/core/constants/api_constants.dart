import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get kakaoRestApiKey =>
      const String.fromEnvironment('KAKAO_REST_API_KEY').isNotEmpty
          ? const String.fromEnvironment('KAKAO_REST_API_KEY')
          : dotenv.env['KAKAO_REST_API_KEY'] ?? '';

  static String get nlApiKey =>
      const String.fromEnvironment('NL_API_KEY').isNotEmpty
          ? const String.fromEnvironment('NL_API_KEY')
          : dotenv.env['NL_API_KEY'] ?? '';
}
