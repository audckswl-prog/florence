import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/router.dart';
import 'config/theme.dart';
import 'data/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (native 빌드용)
  await dotenv.load(fileName: ".env").catchError((_) {
    // Web 배포 시엔 .env 파일이 없어도 괜찮음 (--dart-define 사용)
  });

  // Supabase Credentials
  // 1) --dart-define으로 주입된 값을 우선 사용
  // 2) 없으면 .env 파일에서 가져옴 (native 개발용 fallback)
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL').isNotEmpty
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey =
      const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  try {
    await SupabaseService().initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runApp(const ProviderScope(child: FlorenceApp()));
}

class FlorenceApp extends ConsumerWidget {
  const FlorenceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // 웹 빌드 시 셰이더 컴파일 에러를 피하기 위해
    // InkRipple (기본 물결) 사용, InkSparkle (반짝이) 비활성화
    final theme = kIsWeb
        ? AppTheme.lightTheme.copyWith(splashFactory: InkRipple.splashFactory)
        : AppTheme.lightTheme;

    return MaterialApp.router(
      title: '피렌체 (Florence)',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // 웹에서 stretch_effect 셰이더 비활성화
      scrollBehavior: kIsWeb
          ? const MaterialScrollBehavior().copyWith(overscroll: false)
          : null,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
    );
  }
}
