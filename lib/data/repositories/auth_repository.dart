import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter/services.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      // Optionally sign out of Google/Kakao to allow re-selecting accounts
      try {
        final String webClientId = '1009821725496-vsqbamhgdqbfrdrs0fkkoamcoqobr12l.apps.googleusercontent.com';
        final String iosClientId = '1009821725496-mhd8koitlhaupgfpeprm63ep8g46hmdo.apps.googleusercontent.com';
        final String? clientId = kIsWeb 
            ? webClientId 
            : (Platform.isIOS || Platform.isMacOS ? iosClientId : null);

        await GoogleSignIn(
          clientId: clientId,
          serverClientId: webClientId,
        ).signOut();
      } catch (_) {}
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final String webClientId = '1009821725496-vsqbamhgdqbfrdrs0fkkoamcoqobr12l.apps.googleusercontent.com';
      final String iosClientId = '1009821725496-mhd8koitlhaupgfpeprm63ep8g46hmdo.apps.googleusercontent.com';
      
      // 1. Google Native Login
      final String? clientId = kIsWeb 
          ? webClientId 
          : (Platform.isIOS || Platform.isMacOS ? iosClientId : null);

      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: clientId,
        serverClientId: webClientId,
      ).signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was canceled.');
      }
      
      // 2. Get tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;
      
      if (idToken == null) {
        throw Exception('Failed to get Google ID token.');
      }

      // 3. Authenticate with Supabase
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      throw Exception('Google Login failed: $e');
    }
  }

  Future<void> signInWithKakao() async {
    try {
      // 1. Kakao Native Login
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            throw Exception('Kakao sign-in was canceled.');
          }
          // Fallback to web login
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final idToken = token.idToken;
      if (idToken == null) {
        throw Exception('Kakao login did not return an ID token. OpenID Connect must be enabled in Kakao Developers.');
      }

      // 2. Authenticate with Supabase using the OIDC token
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.kakao,
        idToken: idToken,
      );
    } catch (e) {
      throw Exception('Kakao Login failed: $e');
    }
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
