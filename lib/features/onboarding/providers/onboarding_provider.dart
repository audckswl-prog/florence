import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 앱 시작 시 main.dart에서 override 해야 합니다.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class OnboardingStateNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'has_seen_onboarding';

  OnboardingStateNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_key, true);
    state = true;
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingStateNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingStateNotifier(prefs);
});
