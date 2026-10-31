import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/kakao_book_service.dart';
import '../../../data/services/national_library_service.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/constants/api_constants.dart';

final kakaoBookServiceProvider = Provider<KakaoBookService>((ref) {
  return KakaoBookService(restApiKey: ApiConstants.kakaoRestApiKey);
});

final nationalLibraryServiceProvider = Provider<NationalLibraryService>((ref) {
  return NationalLibraryService(certKey: ApiConstants.nlApiKey);
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final kakaoService = ref.watch(kakaoBookServiceProvider);
  final nlService = ref.watch(nationalLibraryServiceProvider);
  return BookRepositoryImpl(kakaoService, nlService);
});

final supabaseRepositoryProvider = Provider<SupabaseRepository>((ref) {
  return SupabaseRepository(SupabaseService().client);
});
