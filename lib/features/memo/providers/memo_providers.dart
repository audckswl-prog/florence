import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/memo_model.dart';
import '../../library/providers/book_providers.dart';

final memosProvider = FutureProvider.family<List<Memo>, String>((ref, isbn) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  return repository.getMemos(userId, isbn);
});

final memosForUserProvider = FutureProvider.family<List<Memo>, ({String userId, String isbn})>((ref, arg) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  return repository.getMemos(arg.userId, arg.isbn);
});
