import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // 책 위쪽 여유 공간 비율 (칸 높이의 15%)
  static const double _topMarginRatio = 0.15;

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

              const double marginH = 20.0;
              const double marginV = 16.0;
              final double shelfOuterW = screenW - marginH * 2;
              final double shelfOuterH = screenH - marginV * 2;

              final double innerW = shelfOuterW - _frameSide * 2;
              // 50 = Firenze 헤더 높이, _frameSide = 하단 프레임
              final double innerH =
                  shelfOuterH - _frameSide - 50.0;

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
              // 각 칸 = 상단여유(15%) + 책높이(170) + 선반두께(8)
              double optimalScale = 1.0;
              List<List<int>> optimalShelves = [];
              const double bookH = 170.0;
              // 칸 전체 높이 = bookH * (1 + topMarginRatio) + shelfThickness
              final double compartmentBaseH =
                  bookH * (1.0 + _topMarginRatio) + _shelfThickness;

              for (double s = 1.0; s >= 0.08; s -= 0.01) {
                List<List<int>> testShelves = [];
                List<int> currentRow = [];
                double currentRowW = 0.0;

                for (int i = 0; i < originalWidths.length; i++) {
                  double scaledW = originalWidths[i] * s;
                  if (currentRowW + scaledW > innerW &&
                      currentRow.isNotEmpty) {
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

                double totalH = testShelves.length * compartmentBaseH * s;

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

              // 빈 공간을 상단에 모아서 책장 상단 빈 칸처럼 보이게
              final double totalShelvesH =
                  displayShelves.length * compartmentBaseH * optimalScale;
              final double topGap =
                  (innerH - totalShelvesH).clamp(0.0, double.infinity);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: marginH,
                  vertical: marginV,
                ),
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
                      // ──── Firenze 헤더 (필기체 + 음각) ────
                      Container(
                        width: double.infinity,
                        height: 50.0,
                        color: _frameColor,
                        child: Center(
                          child: Text(
                            'Firenze',
                            style: GoogleFonts.greatVibes(
                              fontSize: 30,
                              color: const Color(0xFF3A0E0E), // 프레임보다 어두운 색 (파인 부분)
                              shadows: [
                                // 음각 효과: 아래쪽에 밝은 하이라이트
                                Shadow(
                                  color: Colors.white.withOpacity(0.3),
                                  offset: const Offset(0.5, 1.0),
                                  blurRadius: 0.5,
                                ),
                                // 음각 효과: 위쪽에 어두운 그림자
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(-0.5, -0.5),
                                  blurRadius: 0.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ──── 책장 내부 ────
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 상단 빈 공간 (책장 위쪽 빈 칸)
                            if (topGap > 0) SizedBox(height: topGap),
                            // 선반들
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

  /// 선반 한 칸: 상단 여유 공간 + 책들 + 선반 바닥
  Widget _buildShelfCompartment(
    List<int> indices,
    List<UserBook> allBooks,
    double scale,
  ) {
    final double bookAreaH = 170.0 * scale;
    final double topMargin = bookAreaH * _topMarginRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 상단 여유 공간 (책장 안에 책 위로 빈 공간)
        SizedBox(height: topMargin),
        // 책 영역: clipBehavior로 삐져나옴 방지
        SizedBox(
          height: bookAreaH,
          child: ClipRect(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end, // 선반 바닥에 안착
              children: indices.map((i) {
                final book = allBooks[i];
                int pages = book.book.pageCount;
                if (pages == 0) {
                  final r = Random(book.isbn.hashCode);
                  pages = 200 + r.nextInt(400);
                }
                final int readPages = book.readPages;
                final int totalPages = book.totalPages ?? pages;
                double ratio = 1.0;
                if (readPages > 0 &&
                    totalPages > 0 &&
                    readPages <= totalPages) {
                  ratio = readPages / totalPages;
                }
                final double origW =
                    ((18.0 + (pages * 0.08)) * ratio).clamp(14.0, 70.0);
                final double scaledW = origW * scale;
                final double origH =
                    150.0 +
                    (Random(book.isbn.hashCode).nextDouble() * 20.0);
                final double scaledH = origH * scale;

                return SizedBox(
                  width: scaledW,
                  height: scaledH,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: origW,
                      height: origH,
                      child: BookSpineWidget(
                        key: ValueKey(book.isbn),
                        userBook: book,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // 선반 바닥 (칸막이)
        Container(
          width: double.infinity,
          height: _shelfThickness * scale,
          color: _frameColor,
        ),
      ],
    );
  }
}
