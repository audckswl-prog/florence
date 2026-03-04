import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_book_model.dart';
import '../widgets/book_spine_widget.dart';

class LibraryArchiveScreen extends StatelessWidget {
  final List<UserBook> books;

  const LibraryArchiveScreen({super.key, required this.books});

  // 책장 프레임 색상
  static const Color _frameColor = Color(0xFF5A1E1E);
  // 책장 내부 벽 색상
  static const Color _innerWall = Color(0xFFF5F1EC);
  // 프레임 두께
  static const double _frameSide = 10.0;
  static const double _shelfThickness = 8.0;

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
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenW = constraints.maxWidth;
              final double screenH = constraints.maxHeight;

              // 책장 가구의 가로/세로 마진
              const double marginH = 20.0;
              const double marginV = 16.0;
              final double shelfOuterW = screenW - marginH * 2;
              final double shelfOuterH = screenH - marginV * 2;

              // 내부 사용 가능 영역 (프레임 두께 제외)
              final double innerW = shelfOuterW - _frameSide * 2;
              final double innerH = shelfOuterH - _frameSide - 50.0; // 50 = 상단 Firenze 패널 높이

              if (books.isEmpty || innerW <= 0 || innerH <= 0) {
                return const SizedBox.shrink();
              }

              // 책 원본 너비 계산
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

              // 스케일 찾기
              double optimalScale = 1.0;
              List<List<int>> optimalShelves = [];
              const double bookH = 170.0;

              for (double s = 1.0; s >= 0.08; s -= 0.01) {
                List<List<int>> testShelves = [];
                List<int> currentRow = [];
                double currentRowW = 0.0;

                for (int i = 0; i < originalWidths.length; i++) {
                  double scaledW = originalWidths[i] * s;
                  if (currentRowW + scaledW > innerW && currentRow.isNotEmpty) {
                    testShelves.add(currentRow);
                    currentRow = [];
                    currentRowW = 0.0;
                  }
                  currentRow.add(i);
                  currentRowW += scaledW;
                }
                if (currentRow.isNotEmpty) {
                  testShelves.add(currentRow);
                }

                // 각 칸 = 책 높이 + 선반 두께
                double unitH = (bookH + _shelfThickness) * s;
                double totalH = testShelves.length * unitH;

                if (totalH <= innerH) {
                  optimalScale = s;
                  optimalShelves = testShelves;
                  break;
                }
              }

              if (optimalShelves.isEmpty) {
                optimalScale = 0.1;
                List<int> currentRow = [];
                double currentRowW = 0.0;
                for (int i = 0; i < originalWidths.length; i++) {
                  double scaledW = originalWidths[i] * optimalScale;
                  if (currentRowW + scaledW > innerW &&
                      currentRow.isNotEmpty) {
                    optimalShelves.add(currentRow);
                    currentRow = [];
                    currentRowW = 0.0;
                  }
                  currentRow.add(i);
                  currentRowW += scaledW;
                }
                if (currentRow.isNotEmpty) {
                  optimalShelves.add(currentRow);
                }
              }

              // 최신 책이 위로
              final displayShelves = optimalShelves.reversed.toList();

              // 책장 내부 높이와 선반 총 높이 비교해서 균등 분배
              final double unitH =
                  (bookH + _shelfThickness) * optimalScale;
              final double totalShelvesH =
                  displayShelves.length * unitH;
              final double extraSpace = innerH - totalShelvesH;
              // 빈 공간을 최상단에 배치 (책장 상단 빈칸처럼 보이게)
              final double topGap = extraSpace > 0 ? extraSpace : 0;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: marginH,
                  vertical: marginV,
                ),
                // 흰 배경 위에 놓인 "책장 가구" 오브젝트
                child: Container(
                  width: shelfOuterW,
                  height: shelfOuterH,
                  decoration: BoxDecoration(
                    color: _innerWall,
                    border: Border.all(
                      color: _frameColor,
                      width: _frameSide,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 상단 Firenze 헤더
                      Container(
                        width: double.infinity,
                        height: 50.0,
                        color: _frameColor,
                        child: Center(
                          child: Text(
                            'Firenze',
                            style: TextStyle(
                              fontFamily: 'GreatVibes',
                              fontSize: 28,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                                Shadow(
                                  color: Colors.white.withOpacity(0.15),
                                  offset: const Offset(-1, -1),
                                  blurRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 책장 내부: 상단 빈 공간 + 선반들
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (topGap > 0) SizedBox(height: topGap),
                            ...displayShelves.map((indices) {
                              return _buildShelfCompartment(
                                indices,
                                books,
                                optimalScale,
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 선반 한 칸: 책들 + 아래 칸막이
  Widget _buildShelfCompartment(
    List<int> indices,
    List<UserBook> allBooks,
    double scale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 책 영역
        SizedBox(
          height: 170.0 * scale,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: indices.map((i) {
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: BookSpineWidget(
                    key: ValueKey(allBooks[i].isbn),
                    userBook: allBooks[i],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // 선반 바닥
        Container(
          width: double.infinity,
          height: _shelfThickness * scale,
          color: _frameColor,
        ),
      ],
    );
  }
}
