import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../data/models/book_model.dart';
import '../../library/providers/book_providers.dart';
import '../../library/providers/library_providers.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/book_detail_modal.dart';
import '../widgets/reading_completion_dialog.dart';
import '../screens/reading_ticket_screen.dart';

class BookSearchDelegate extends SearchDelegate<Book?> {
  final WidgetRef ref;
  final Function(Book)? onBookSelected; // Optional callback for selection mode

  BookSearchDelegate(this.ref, {this.onBookSelected});

  @override
  String get searchFieldLabel => '책 제목, 저자 등으로 검색';

  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(color: AppColors.black, fontSize: 16);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.grey),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.black),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) return Container();

    return FutureBuilder<List<Book>>(
      future: ref.read(bookRepositoryProvider).searchBooks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: FlorenceLoader());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                '앗, 도서 정보를 불러오지 못했어요.\n일시적인 네트워크 문제이거나 찾을 수 없는 도서일 수 있습니다.\n스페이싱 등 오탈자를 확인 후 다시 검색해주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          );
        }

        final books = snapshot.data ?? [];

        if (books.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                '입력하신 검색어와 일치하는 책이 피렌체에 등록되어 있지 않습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookListTile(
              book: book,
              onTap: () {
                if (onBookSelected != null) {
                  onBookSelected!(book);
                  close(context, book);
                } else {
                  showModalBottomSheet<dynamic>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => BookDetailModal(book: book),
                  ).then((result) {
                    if (result == true) {
                      ref.invalidate(userBooksProvider);
                    }
                  });
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // No suggestions for now
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }
}
