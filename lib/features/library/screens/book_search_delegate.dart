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
          return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
        }

        final books = snapshot.data ?? [];

        if (books.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
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
                  ).then((result) async {
                    if (result == true) {
                      ref.invalidate(userBooksProvider);
                    } else if (result is Map<String, dynamic> &&
                        result['action'] == 'read_completed') {
                      final nav = Navigator.of(context);
                      ref.invalidate(userBooksProvider);
                      final mockUserBook = result['book'];
                      final quote = await showDialog<String>(
                        context: context,
                        builder: (context) =>
                            ReadingCompletionDialog(userBook: mockUserBook),
                      );

                      if (quote != null) {
                        nav.push(
                          MaterialPageRoute(
                            builder: (context) => ReadingTicketScreen(
                              userBook: mockUserBook,
                              quote: quote,
                            ),
                          ),
                        );
                      }
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
