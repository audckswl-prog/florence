import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get kakaoRestApiKey {
    const envKey = String.fromEnvironment('KAKAO_REST_API_KEY');
    if (envKey.trim().isNotEmpty) return envKey.trim();

    final dotenvKey = dotenv.env['KAKAO_REST_API_KEY']?.trim() ?? '';
    if (dotenvKey.isNotEmpty) return dotenvKey;

    return '99b2c955d8bffeeae97e2a6ad6b47c60';
  }

  static String get nlApiKey {
    const envKey = String.fromEnvironment('NL_API_KEY');
    if (envKey.trim().isNotEmpty) return envKey.trim();

    final dotenvKey = dotenv.env['NL_API_KEY']?.trim() ?? '';
    if (dotenvKey.isNotEmpty) return dotenvKey;

    return '1af2e0f3fbb910838be8937362c3bb445776676cd75e3b27f1c94b07a07ed46c';
  }
}
