import 'dart:math';
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_book_model.dart';
import '../widgets/book_spine_widget.dart';

class LibraryArchiveScreen extends StatelessWidget {
  final List<UserBook> books;

  const LibraryArchiveScreen({super.key, required this.books});

  // 고동색 원목 색상 팔레트 (무광 질감)
  static const Color _woodDark = Color(0xFF2B1D14);      // 아주 어두운 고동색 (그림자)
  static const Color _woodMid = Color(0xFF4A3324);       // 중간 고동색 베이스
  static const Color _woodLight = Color(0xFF5E4331);     // 밝은 고동색
  static const Color _woodHighlight = Color(0xFF6E513D); // 빛망울 (Bevel 표면)
  // 책장 내부 벽면 (책장 프레임과 이어지는 깊고 어두운 톤)
  static const Color _innerWall = AppColors.ivory; // 배경과 동일한 밝은 단색 적용

  static const double _shelfThickness = 12.0;
  static const double _headerHeight = 50.0;
  static const double _bookSidePadding = 12.0; // 양옆 여백 강화

  /// 각 선반(Shelf) 바닥 (오픈형 플로팅 디자인)
  static BoxDecoration _shelfDecoration(double scale) {
    return BoxDecoration(
      color: _woodDark, // 무광 고동색 테마
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: Offset(0, 4 * scale), // 선반 바로 아래 그림자 (가벼운 입체감)
          blurRadius: 6 * scale,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.charcoal),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 배경: 가장 뒷 배경을 화면 전체 AppColors.ivory 단색으로 설정 ──
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.ivory,
          ),
          
          // ── 책장 몸체 (Scrollable) ──
          SafeArea(
            child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenW = constraints.maxWidth;
            final double screenH = constraints.maxHeight;

            if (books.isEmpty) return const SizedBox.shrink();

            const double marginH = 24.0;
            final double shelfOuterW = screenW - marginH * 2;
            final double innerW = shelfOuterW - _bookSidePadding * 2;

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
            const double topPad = 25.0;
            const double compartmentH = topPad + bookH + _shelfThickness;

            List<List<int>> shelves =
                _arrangeBooksOnShelves(originalWidths, innerW, 1.0);
            double shelfOuterH = _headerHeight + shelves.length * compartmentH;

            final double maxH = screenH * 0.92;
            double scale = 1.0;

            if (shelfOuterH > maxH) {
              for (double s = 0.99; s >= 0.08; s -= 0.01) {
                shelves = _arrangeBooksOnShelves(
                    originalWidths, innerW, s);
                final double scaledCH = compartmentH * s;
                shelfOuterH = _headerHeight + shelves.length * scaledCH;
                if (shelfOuterH <= maxH) {
                  scale = s;
                  break;
                }
              }
            }

            final displayShelves = shelves.reversed.toList();
            final double scaledCH = compartmentH * scale;
            final double actualInnerH = displayShelves.length * scaledCH;
            final double actualOuterH = _headerHeight + actualInnerH;
            final double verticalMargin =
                ((screenH - actualOuterH) / 2).clamp(8.0, double.infinity);

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: marginH,
                  vertical: verticalMargin,
                ),
                // ─── 오픈형 책장 (플로팅 쉘프) ───
                child: Container(
                  width: shelfOuterW,
                  height: actualOuterH,
                  color: Colors.transparent, // 프레임 없는 투명 구조
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Firenze 헤더 (테두리 나무 느낌 없이 공중에 띄운 글자)
                      Container(
                        width: double.infinity,
                        height: _headerHeight,
                        color: Colors.transparent,
                        child: Center(
                          child: Text(
                            'Firenze',
                            style: GoogleFonts.greatVibes(
                              fontSize: 34,
                              color: AppColors.charcoal,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
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
                ), // Container
            ), // Padding
          ); // SingleChildScrollView
        }, // LayoutBuilder builder
      ), // LayoutBuilder
    ), // SafeArea
        ], // Stack children
      ), // body: Stack
    ); // Scaffold
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
    final double topPad = 25.0 * scale;

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
        // 선반 바닥 — 무광 입체 질감
        Container(
          width: double.infinity,
          height: _shelfThickness * scale,
          decoration: _shelfDecoration(scale),
        ),
      ],
    );
  }
}
