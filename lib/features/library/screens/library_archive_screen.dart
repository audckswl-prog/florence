import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_book_model.dart';
import '../widgets/book_spine_widget.dart';

class LibraryArchiveScreen extends StatelessWidget {
  final List<UserBook> books;

  const LibraryArchiveScreen({super.key, required this.books});

  // 마호가니 원목 색상 팔레트
  static const Color _woodDark = Color(0xFF3E1008);
  static const Color _woodMid = Color(0xFF5C1A10);
  static const Color _woodLight = Color(0xFF7A2E1C);
  static const Color _woodHighlight = Color(0xFF8B3A22);
  static const Color _woodGrain = Color(0xFF4A1209);
  static const Color _innerWall = Color(0xFFF5F1EC);
  static const double _frameSide = 10.0;
  static const double _shelfThickness = 8.0;
  static const double _headerHeight = 50.0;
  static const double _bookSidePadding = 8.0;

  /// 수평 나무결 그라데이션
  static const BoxDecoration _hWood = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _woodMid, _woodLight, _woodHighlight, _woodLight,
        _woodMid, _woodGrain, _woodMid, _woodLight, _woodMid, _woodDark,
      ],
      stops: [0.0, 0.1, 0.2, 0.35, 0.5, 0.55, 0.65, 0.8, 0.9, 1.0],
    ),
  );

  /// 수직 나무결 그라데이션
  static const BoxDecoration _vWood = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _woodMid, _woodLight, _woodMid, _woodGrain,
        _woodMid, _woodLight, _woodMid, _woodDark,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF140F0D), // 어두운 방 배경색
        gradient: RadialGradient(
          center: Alignment(0, -0.2), // 살짝 위쪽을 비추는 조명
          radius: 0.8,
          colors: [
            Color(0xFF3A2920), // 백열등이 비추는 따뜻한 중심부
            Color(0xFF140F0D), // 어두운 주변부
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white70),
        ),
        body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenW = constraints.maxWidth;
            final double screenH = constraints.maxHeight;

            if (books.isEmpty) return const SizedBox.shrink();

            const double marginH = 24.0;
            final double shelfOuterW = screenW - marginH * 2;
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

            // 스케일 찾기
            const double bookH = 170.0;
            const double topPad = 20.0;
            const double compartmentH = topPad + bookH + _shelfThickness;

            List<List<int>> shelves =
                _arrangeBooksOnShelves(originalWidths, innerW, 1.0);
            double shelfOuterH = _frameSide + _headerHeight +
                shelves.length * compartmentH + _frameSide;

            final double maxH = screenH * 0.92;
            double scale = 1.0;

            if (shelfOuterH > maxH) {
              for (double s = 0.99; s >= 0.08; s -= 0.01) {
                shelves = _arrangeBooksOnShelves(
                    originalWidths, innerW, s);
                final double scaledCH = compartmentH * s;
                shelfOuterH = _frameSide + _headerHeight +
                    shelves.length * scaledCH + _frameSide;
                if (shelfOuterH <= maxH) {
                  scale = s;
                  break;
                }
              }
            }

            final displayShelves = shelves.reversed.toList();
            final double scaledCH = compartmentH * scale;
            final double actualInnerH = displayShelves.length * scaledCH;
            final double actualOuterH =
                _frameSide + _headerHeight + actualInnerH + _frameSide;
            final double verticalMargin =
                ((screenH - actualOuterH) / 2).clamp(8.0, double.infinity);

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: marginH,
                  vertical: verticalMargin,
                ),
                // ─── 책장 가구 본체 ───
                child: Container(
                  width: shelfOuterW,
                  height: actualOuterH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6), // 어두운 방에 어울리는 깊은 그림자
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: Stack(
                      children: [
                        // 상단 프레임
                      Positioned(
                        top: 0, left: 0, right: 0,
                        height: _frameSide,
                        child: Container(decoration: _hWood),
                      ),
                      // 하단 프레임
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        height: _frameSide,
                        child: Container(decoration: _hWood),
                      ),
                      // 좌측 프레임
                      Positioned(
                        top: 0, bottom: 0, left: 0,
                        width: _frameSide,
                        child: Container(decoration: _vWood),
                      ),
                      // 우측 프레임
                      Positioned(
                        top: 0, bottom: 0, right: 0,
                        width: _frameSide,
                        child: Container(decoration: _vWood),
                      ),
                      // 내부 콘텐츠
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(_frameSide),
                          child: Container(
                            color: _innerWall,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Firenze 헤더 (나무 질감 + 필기체 + 음각)
                                Container(
                                  width: double.infinity,
                                  height: _headerHeight,
                                  decoration: _hWood,
                                  child: Center(
                                    child: Text(
                                      'Firenze',
                                      style: GoogleFonts.greatVibes(
                                        fontSize: 28,
                                        color: const Color(0xFF2A0A04),
                                        shadows: [
                                          Shadow(
                                            color: Colors.white
                                                .withOpacity(0.25),
                                            offset: const Offset(0.5, 1.0),
                                            blurRadius: 0.5,
                                          ),
                                          Shadow(
                                            color: Colors.black
                                                .withOpacity(0.6),
                                            offset:
                                                const Offset(-0.5, -0.5),
                                            blurRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // 선반들
                                ...displayShelves.map((indices) {
                                  return _buildShelfCompartment(
                                    indices, books, scale,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ), // Stack
                ), // ClipRRect
              ), // Container (formerly SizedBox)
            ), // Padding
          ); // SingleChildScrollView
        }, // LayoutBuilder builder
      ), // LayoutBuilder
    ), // SafeArea
  ), // Scaffold
); // Container
} // build method

  List<List<int>> _arrangeBooksOnShelves(
    List<double> widths, double availableW, double scale,
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
    if (currentRow.isNotEmpty) shelves.add(currentRow);
    return shelves;
  }

  Widget _buildShelfCompartment(
    List<int> indices, List<UserBook> allBooks, double scale,
  ) {
    final double bookAreaH = 170.0 * scale;
    final double topPad = 20.0 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: topPad),
        SizedBox(
          height: bookAreaH,
          child: ClipRect(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: _bookSidePadding * scale),
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
                  final double origH = 150.0 +
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
        // 선반 바닥 — 나무 질감
        Container(
          width: double.infinity,
          height: _shelfThickness * scale,
          decoration: _hWood,
        ),
      ],
    );
  }
}
