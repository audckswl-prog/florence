import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/scaffold_with_nav_bar.dart';
import '../features/library/screens/reading_list_screen.dart';
import '../features/memo/screens/memo_screen.dart';
import '../features/memo/screens/memo_list_screen.dart';
import '../features/memo/screens/write_memo_screen.dart';
import '../features/memo/screens/add_photo_memo_screen.dart';
import '../data/models/book_model.dart';
import '../features/mypage/screens/mypage_screen.dart';
import '../features/social/screens/create_project_screen.dart';
import '../features/social/screens/project_detail_screen.dart';
import '../data/models/project_model.dart';
import '../features/social/screens/project_receipt_screen.dart';
import '../features/social/screens/ai_chat_screen.dart';
import '../features/settings/screens/settings_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Use the repository stream directly
  final authStateStream = ref.watch(authRepositoryProvider).authStateChanges;
  final authState = ref.watch(
    authStateProvider,
  ); // Keep watching state for redirect logic

  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final sectionHomeNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'sectionHomeNav',
  );
  final sectionMemoNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'sectionMemoNav',
  );
  final sectionReadingListNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'sectionReadingListNav',
  );
  final sectionMyPageNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'sectionMyPageNav',
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      final isLoggingIn =
          state.uri.toString() == '/login' || state.uri.toString() == '/signup';
      final isSplash = state.uri.toString() == '/splash';

      // 1. Force redirect from Splash
      if (isSplash) {
        return isLoggedIn ? '/home' : '/login';
      }

      // 2. Protect routes
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // 3. Prevent logged-in users from seeing login screen
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            navigatorKey: sectionHomeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'social/create',
                    builder: (context, state) => const CreateProjectScreen(),
                  ),
                  GoRoute(
                    path: 'social/detail/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final project = state.extra as Project?;
                      return ProjectDetailScreen(
                        projectId: id,
                        project: project,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'ai-chat',
                        builder: (context, state) {
                          final project = state.extra as Project;
                          return AiChatScreen(project: project);
                        },
                      ),
                      GoRoute(
                        path: 'receipt',
                        builder: (context, state) {
                          final extras = state.extra as Map<String, dynamic>;
                          return ProjectReceiptScreen(
                            project: extras['project'] as Project,
                            completionRate: extras['rate'] as double,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Memo Branch
          StatefulShellBranch(
            navigatorKey: sectionMemoNavigatorKey,
            routes: [
              GoRoute(
                path: '/memo',
                builder: (context, state) => const MemoScreen(),
                routes: [
                  GoRoute(
                    path: 'list/:isbn',
                    builder: (context, state) {
                      final isbn = state.pathParameters['isbn']!;
                      final book = state.extra as Book?;
                      return MemoListScreen(isbn: isbn, book: book);
                    },
                  ),
                  GoRoute(
                    path: 'write/:isbn',
                    builder: (context, state) {
                      final isbn = state.pathParameters['isbn']!;
                      final book = state.extra as Book?;
                      return WriteMemoScreen(isbn: isbn, book: book);
                    },
                  ),
                  GoRoute(
                    path: 'add-photo/:isbn',
                    builder: (context, state) {
                      final isbn = state.pathParameters['isbn']!;
                      final book = state.extra as Book?;
                      return AddPhotoMemoScreen(isbn: isbn, book: book);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Reading List Branch (Record)
          StatefulShellBranch(
            navigatorKey: sectionReadingListNavigatorKey,
            routes: [
              GoRoute(
                path: '/reading-list',
                builder: (context, state) => const ReadingListScreen(),
              ),
            ],
          ),
          // My Page Branch
          StatefulShellBranch(
            navigatorKey: sectionMyPageNavigatorKey,
            routes: [
              GoRoute(
                path: '/mypage',
                builder: (context, state) => const MyPageScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
