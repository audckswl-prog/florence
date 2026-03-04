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

  // 버건디 원목 색상 팔레트 (AppColors.burgundy 기반, 무광 질감)
  static const Color _woodDark = Color(0xFF3B080A);      // 아주 어두운 와인색 (그림자)
  static const Color _woodMid = AppColors.burgundy;      // 기본 앱 버건디 (#751013)
  static const Color _woodLight = Color(0xFF8B181C);     // 활기가 도는 밝은 버건디
  static const Color _woodHighlight = Color(0xFF9A2024); // AppColors.burgundyLight (빛망울)
  // 책장 내부 벽면 (책장 프레임과 이어지는 깊고 어두운 톤)
  static const Color _innerWall = AppColors.ivory; // 배경과 동일한 밝은 단색 적용

  static const double _frameSide = 12.0; // 프레임 약간 두껍게 안정감 부여
  static const double _shelfThickness = 12.0;
  static const double _headerHeight = 50.0;
  static const double _bookSidePadding = 8.0;

  /// 수평 프레임 (상단/하단 베벨 및 무광 디자인)
  static const BoxDecoration _hWood = BoxDecoration(
    color: _woodMid,
    border: Border(
      top: BorderSide(color: _woodHighlight, width: 1.5), // 빛망울(Bevel 표면)
      bottom: BorderSide(color: _woodDark, width: 2.0),   // 그림자(Bevel 아랫면)
    ),
  );

  /// 수직 프레임 (좌우 베벨 및 무광 디자인)
  static const BoxDecoration _vWood = BoxDecoration(
    color: _woodMid,
    border: Border(
      left: BorderSide(color: _woodHighlight, width: 1.5),
      right: BorderSide(color: _woodDark, width: 2.0),
    ),
  );

  /// 각 선반(Shelf) 바닥 (3D 그림자 포함)
  static BoxDecoration _shelfDecoration(double scale) {
    return BoxDecoration(
      color: _woodMid,
      border: Border(
        top: BorderSide(color: _woodHighlight, width: 1.5 * scale),
        bottom: BorderSide(color: _woodDark, width: 2.0 * scale),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: Offset(0, 4 * scale), // 선반 바로 아래 그림자 (깊이감)
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
        iconTheme: const IconThemeData(color: Colors.white70),
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
                            decoration: BoxDecoration(
                              color: _innerWall,
                              boxShadow: [
                                // 책장 내부 전체에 드리우는 은은한 상단 그림자
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                  spreadRadius: -2,
                                  blurStyle: BlurStyle.inner, // 내부 그림자로 깊이감 구현
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Firenze 헤더 (무광 나무 질감 + 깊이감 있는 음각)
                                Container(
                                  width: double.infinity,
                                  height: _headerHeight,
                                  decoration: _hWood.copyWith(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        offset: const Offset(0, 3),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Firenze',
                                      style: GoogleFonts.greatVibes(
                                        fontSize: 28,
                                        color: AppColors.charcoal, // 텍스트를 검정 계열(Charcoal)으로 변경
                                        shadows: [
                                          Shadow(
                                            color: Colors.white.withOpacity(0.5), // 양각 느낌의 밝은 하이라이트 투명하게
                                            offset: const Offset(1.0, 1.0),
                                            blurRadius: 1.0,
                                          ),
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3), // 약간의 그림자 추가
                                            offset: const Offset(-0.5, -0.5),
                                            blurRadius: 1.0,
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
