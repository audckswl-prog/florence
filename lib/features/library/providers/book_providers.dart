import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/aladin_service.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/constants/api_constants.dart';

final aladinServiceProvider = Provider<AladinService>((ref) {
  return AladinService(ttbKey: ApiConstants.aladinTtbKey);
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final aladinService = ref.watch(aladinServiceProvider);
  return BookRepositoryImpl(aladinService);
});

final supabaseRepositoryProvider = Provider<SupabaseRepository>((ref) {
  return SupabaseRepository(SupabaseService().client);
});
