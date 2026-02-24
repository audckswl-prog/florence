import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/user_book_model.dart';
import 'book_providers.dart';

final userBooksProvider = FutureProvider.autoDispose<List<UserBook>>((ref) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  // Fetch 'reading' and 'read' books for the library stack (exclude 'wish' for now, or include all?)
  // The spec says "Main Storage" includes selected books. 'Wish' books go to another tab?
  // Spec: "'읽고 싶은 책' 선정 시 [읽는 중/읽고 싶은 책] 보관함으로 이동"
  // "내 서재 탭: ... 기록해둔 책들 노출" -> This likely implies 'read' or 'reading' or both.
  // Let's fetch all for now and filter in UI if needed, or just fetch reading+read.
  // For the "stacking" visualization, it usually represents read books or reading books.
  // Let's fetch all.
  
  final data = await repository.getUserBooks(userId);
  return data.map((json) => UserBook.fromJson(json)).toList();
});

final readBooksProvider = Provider.autoDispose<AsyncValue<List<UserBook>>>((ref) {
  return ref.watch(userBooksProvider).whenData(
        (books) => books.where((book) => book.status == 'read').toList(),
      );
});

final readingListProvider = Provider.autoDispose<AsyncValue<List<UserBook>>>((ref) {
  return ref.watch(userBooksProvider).whenData(
        (books) => books.where((book) => book.status == 'reading' || book.status == 'wish').toList(),
      );
});

final readBooksThisYearProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  return ref.watch(userBooksProvider).whenData((books) {
    final currentYear = DateTime.now().year;
    return books.where((book) {
      if (book.status != 'read') return false;
      if (book.finishedAt == null) return false;
      return book.finishedAt!.year == currentYear;
    }).length;
  });
});
