import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_book_model.dart';
import '../widgets/book_spine_widget.dart';

class LibraryArchiveScreen extends StatelessWidget {
  final List<UserBook> books;

  const LibraryArchiveScreen({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4F0),
            border: Border.all(
              color: const Color(0xFF5A1E1E),
              width: 10,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double availableWidth = constraints.maxWidth;
              final double headerHeight = 80.0;
              final double availableHeight =
                  constraints.maxHeight - headerHeight;

              if (books.isEmpty ||
                  availableWidth <= 0 ||
                  availableHeight <= 0) {
                return const SizedBox.shrink();
              }

              // 책들의 원본 너비를 계산합니다.
              final List<double> originalWidths = [];
              for (var b in books) {
                int pages = b.book.pageCount;
                if (pages == 0) {
                  final random = Random(b.isbn.hashCode);
                  pages = 200 + random.nextInt(400);
                }
                final int readPages = b.readPages;
                final int totalPages = b.totalPages ?? pages;
                double thicknessRatio = 1.0;
                if (readPages > 0 &&
                    totalPages > 0 &&
                    readPages <= totalPages) {
                  thicknessRatio = readPages / totalPages;
                }
                double w = ((18.0 + (pages * 0.08)) * thicknessRatio)
                    .clamp(14.0, 70.0);
                originalWidths.add(w);
              }

              // 최적의 스케일(S) 찾기
              double optimalScale = 1.0;
              List<List<int>> optimalShelves = [];
              const double shelfDividerHeight = 14.0;
              const double bookAreaHeight = 170.0;

              for (double s = 1.0; s >= 0.1; s -= 0.01) {
                List<List<int>> testShelves = [];
                List<int> currentRow = [];
                double currentRowWidth = 0.0;
                double scaledSpacing = 1.0 * s;

                for (int i = 0; i < originalWidths.length; i++) {
                  double scaledW = originalWidths[i] * s;
                  if (currentRowWidth + scaledW + scaledSpacing >
                          availableWidth &&
                      currentRow.isNotEmpty) {
                    testShelves.add(currentRow);
                    currentRow = [];
                    currentRowWidth = 0.0;
                  }
                  currentRow.add(i);
                  currentRowWidth += scaledW + scaledSpacing;
                }
                if (currentRow.isNotEmpty) {
                  testShelves.add(currentRow);
                }

                double scaledShelfHeight =
                    (bookAreaHeight + shelfDividerHeight) * s;
                double totalRequiredHeight =
                    testShelves.length * scaledShelfHeight;

                if (totalRequiredHeight <= availableHeight) {
                  optimalScale = s;
                  optimalShelves = testShelves;
                  break;
                }
              }

              // fallback
              if (optimalShelves.isEmpty) {
                optimalScale = 0.15;
                List<int> currentRow = [];
                double currentRowWidth = 0.0;
                double scaledSpacing = 1.0 * optimalScale;
                for (int i = 0; i < originalWidths.length; i++) {
                  double scaledW = originalWidths[i] * optimalScale;
                  if (currentRowWidth + scaledW + scaledSpacing >
                          availableWidth &&
                      currentRow.isNotEmpty) {
                    optimalShelves.add(currentRow);
                    currentRow = [];
                    currentRowWidth = 0.0;
                  }
                  currentRow.add(i);
                  currentRowWidth += scaledW + scaledSpacing;
                }
                if (currentRow.isNotEmpty) {
                  optimalShelves.add(currentRow);
                }
              }

              // 최신 선반이 맨 위로
              final reversedShelves = optimalShelves.reversed.toList();

              return Column(
                children: [
                  // 상단 Firenze 타이틀 (버건디 나무판)
                  Container(
                    width: double.infinity,
                    height: headerHeight,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5A1E1E),
                    ),
                    child: Center(
                      child: Text(
                        'Firenze',
                        style: TextStyle(
                          fontFamily: 'GreatVibes',
                          fontSize: 36,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                            Shadow(
                              color: Colors.white.withOpacity(0.2),
                              offset: const Offset(-1, -1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 책장 영역
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF7F4F0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: reversedShelves.map((shelfIndices) {
                          return _buildScaledShelf(
                            shelfIndices,
                            books,
                            optimalScale,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScaledShelf(
    List<int> shelfIndices,
    List<UserBook> allBooks,
    double scale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) 책들이 서 있는 공간
        SizedBox(
          height: 170.0 * scale,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: shelfIndices.map((index) {
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: BookSpineWidget(
                    key: ValueKey(allBooks[index].isbn),
                    userBook: allBooks[index],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // 2) 책장 칸막이
        Container(
          width: double.infinity,
          height: 14.0 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF5A1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: Offset(0, -2 * scale),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 4 * scale,
                offset: Offset(0, 4 * scale),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
