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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.charcoal),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double totalHeight = constraints.maxHeight;
            const double headerHeight = 60.0;
            const double shelfDividerHeight = 10.0;
            const double bookAreaBaseHeight = 170.0;
            final double availableHeight = totalHeight - headerHeight;

            if (books.isEmpty || totalWidth <= 0 || availableHeight <= 0) {
              return const SizedBox.shrink();
            }

            // 책들의 원본 너비를 계산
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

            for (double s = 1.0; s >= 0.1; s -= 0.01) {
              List<List<int>> testShelves = [];
              List<int> currentRow = [];
              double currentRowWidth = 0.0;
              double scaledSpacing = 1.0 * s;

              for (int i = 0; i < originalWidths.length; i++) {
                double scaledW = originalWidths[i] * s;
                if (currentRowWidth + scaledW + scaledSpacing >
                        totalWidth &&
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

              double scaledUnitHeight =
                  (bookAreaBaseHeight + shelfDividerHeight) * s;
              double totalRequired = testShelves.length * scaledUnitHeight;

              if (totalRequired <= availableHeight) {
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
                        totalWidth &&
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

            // 선반들의 총 높이 계산
            final double scaledUnitHeight =
                (bookAreaBaseHeight + shelfDividerHeight) * optimalScale;
            final double totalShelvesHeight =
                reversedShelves.length * scaledUnitHeight;
            // 남는 공간을 선반 사이에 균등 분배
            final double remainingSpace =
                availableHeight - totalShelvesHeight;
            final double gapPerShelf = reversedShelves.length > 1
                ? (remainingSpace / (reversedShelves.length + 1))
                    .clamp(0.0, double.infinity)
                : remainingSpace / 2;

            return Column(
              children: [
                // 상단 Firenze 헤더
                Container(
                  width: double.infinity,
                  height: headerHeight,
                  color: const Color(0xFF5A1E1E),
                  child: Center(
                    child: Text(
                      'Firenze',
                      style: TextStyle(
                        fontFamily: 'GreatVibes',
                        fontSize: 32,
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
                // 책장 영역: 위에서부터 균일하게 채움
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildShelvesWithGaps(
                        reversedShelves,
                        books,
                        optimalScale,
                        gapPerShelf,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildShelvesWithGaps(
    List<List<int>> shelves,
    List<UserBook> allBooks,
    double scale,
    double gap,
  ) {
    final List<Widget> widgets = [];
    for (int i = 0; i < shelves.length; i++) {
      // 선반 위에 균등 간격
      if (gap > 0) {
        widgets.add(SizedBox(height: gap));
      }
      widgets.add(_buildScaledShelf(shelves[i], allBooks, scale));
    }
    return widgets;
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
        // 2) 선반 바닥 (칸막이)
        Container(
          width: double.infinity,
          height: 10.0 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF5A1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 3 * scale,
                offset: Offset(0, 3 * scale),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
