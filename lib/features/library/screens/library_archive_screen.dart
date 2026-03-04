import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_book_model.dart';
import '../widgets/book_spine_widget.dart';

class LibraryArchiveScreen extends StatelessWidget {
  final List<UserBook> books;

  const LibraryArchiveScreen({super.key, required this.books});

  static const Color _frameColor = Color(0xFF5A1E1E);
  static const Color _innerWall = Color(0xFFF5F1EC);
  static const double _frameSide = 10.0;
  static const double _shelfThickness = 8.0;
  static const double _headerHeight = 50.0;
  // 책 좌우 여유 공간
  static const double _bookSidePadding = 8.0;

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
            final double screenW = constraints.maxWidth;
            final double screenH = constraints.maxHeight;

            if (books.isEmpty) {
              return const SizedBox.shrink();
            }

            // 책장의 좌우 마진
            const double marginH = 24.0;
            final double shelfOuterW = screenW - marginH * 2;
            // 내부 사용 가능 너비
            final double innerW =
                shelfOuterW - _frameSide * 2 - _bookSidePadding * 2;

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

            // 먼저 scale=1.0 기준으로 몇 개의 선반이 필요한지 계산
            List<List<int>> shelves = _arrangeBooksOnShelves(
              originalWidths,
              innerW,
              1.0,
            );

            // 한 칸 높이 (책 높이 + 상단 여유 + 선반 두께)
            const double bookH = 170.0;
            const double topPad = 20.0; // 책 위 여유 공간 (고정)
            const double compartmentH = topPad + bookH + _shelfThickness;

            // 책장의 총 내부 높이
            double totalInnerH = shelves.length * compartmentH;

            // 책장 전체 높이 (프레임 + 헤더 + 내부 + 하단 프레임)
            double shelfOuterH =
                _frameSide + _headerHeight + totalInnerH + _frameSide;

            // 최대 높이 제한 (화면의 90%)
            final double maxH = screenH * 0.92;
            double scale = 1.0;

            if (shelfOuterH > maxH) {
              // 화면에 안 들어가면 스케일 다운
              // 스케일 다운 시 선반 재배치도 필요
              for (double s = 0.99; s >= 0.08; s -= 0.01) {
                shelves = _arrangeBooksOnShelves(
                  originalWidths,
                  innerW,
                  s,
                );
                final double scaledCompartmentH =
                    (topPad + bookH + _shelfThickness) * s;
                totalInnerH = shelves.length * scaledCompartmentH;
                shelfOuterH =
                    _frameSide + _headerHeight + totalInnerH + _frameSide;

                if (shelfOuterH <= maxH) {
                  scale = s;
                  break;
                }
              }
            }

            // 최신 책이 위로
            final displayShelves = shelves.reversed.toList();

            // 실제 칸 높이 계산
            final double scaledCompartmentH =
                (topPad + bookH + _shelfThickness) * scale;
            final double actualInnerH =
                displayShelves.length * scaledCompartmentH;
            final double actualOuterH =
                _frameSide + _headerHeight + actualInnerH + _frameSide;

            // 수직 여백 (화면 중앙 정렬)
            final double verticalMargin =
                ((screenH - actualOuterH) / 2).clamp(8.0, double.infinity);

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: marginH,
                  vertical: verticalMargin,
                ),
                child: Container(
                  width: shelfOuterW,
                  decoration: BoxDecoration(
                    color: _innerWall,
                    border: Border.all(
                      color: _frameColor,
                      width: _frameSide,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ──── Firenze 헤더 (필기체 + 음각) ────
                      Container(
                        width: double.infinity,
                        height: _headerHeight,
                        color: _frameColor,
                        child: Center(
                          child: Text(
                            'Firenze',
                            style: GoogleFonts.greatVibes(
                              fontSize: 28,
                              color: const Color(0xFF3A0E0E),
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.3),
                                  offset: const Offset(0.5, 1.0),
                                  blurRadius: 0.5,
                                ),
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
                      // ──── 선반들 ────
                      ...displayShelves.map((indices) {
                        return _buildShelfCompartment(
                          indices,
                          books,
                          scale,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 주어진 스케일에서 책들을 선반에 배치
  List<List<int>> _arrangeBooksOnShelves(
    List<double> widths,
    double availableW,
    double scale,
  ) {
    List<List<int>> shelves = [];
    List<int> currentRow = [];
    double currentRowW = 0.0;

    for (int i = 0; i < widths.length; i++) {
      double scaledW = widths[i] * scale;
      if (currentRowW + scaledW > availableW && currentRow.isNotEmpty) {
        shelves.add(currentRow);
        currentRow = [];
        currentRowW = 0.0;
      }
      currentRow.add(i);
      currentRowW += scaledW;
    }
    if (currentRow.isNotEmpty) {
      shelves.add(currentRow);
    }
    return shelves;
  }

  /// 선반 한 칸: 상단 여유 + 책들 + 선반 바닥
  Widget _buildShelfCompartment(
    List<int> indices,
    List<UserBook> allBooks,
    double scale,
  ) {
    final double bookAreaH = 170.0 * scale;
    final double topPad = 20.0 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 상단 여유 공간
        SizedBox(height: topPad),
        // 책 영역
        SizedBox(
          height: bookAreaH,
          child: ClipRect(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: _bookSidePadding * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
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
        ),
        // 선반 바닥 (칸막이) — 프레임 벽과 이어져야 하므로 패딩 없음
        Container(
          width: double.infinity,
          height: _shelfThickness * scale,
          color: _frameColor,
        ),
      ],
    );
  }
}
