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
    // 가장 오래된 책이 먼저 오도록 정렬되어 전달받았다고 가정
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.charcoal),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 넓은 패딩 대신 좁은 패딩 사용 (많은 책을 보여주기 위해)
          const double horizontalPadding = 16.0;
          const double verticalPadding = 16.0;

          final double availableWidth = constraints.maxWidth - (horizontalPadding * 2);
          final double availableHeight = constraints.maxHeight - (verticalPadding * 2) - 80; // 80은 상단 Firenze 헤더 공간

          if (books.isEmpty || availableWidth <= 0 || availableHeight <= 0) {
            return const SizedBox.shrink();
          }

          // 책들의 원본 (비율 1.0) 너비를 계산합니다.
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
            if (readPages > 0 && totalPages > 0 && readPages <= totalPages) {
              thicknessRatio = readPages / totalPages;
            }
            double w = ((18.0 + (pages * 0.08)) * thicknessRatio).clamp(14.0, 70.0);
            originalWidths.add(w);
          }

          // 최적의 스케일(S) 찾기: 이진 탐색 방식 혹은 0.01씩 줄여나가기
          double optimalScale = 1.0;
          List<List<int>> optimalShelves = [];

          // 최대 스케일 1.0에서 시작해 0.01씩 줄이면서 화면에 딱 맞는 크기를 찾습니다.
          for (double s = 1.0; s >= 0.1; s -= 0.01) {
            List<List<int>> testShelves = [];
            List<int> currentRow = [];
            double currentRowWidth = 0.0;
            double scaledSpacing = 1.0 * s;

            for (int i = 0; i < originalWidths.length; i++) {
              double scaledW = originalWidths[i] * s;
              if (currentRowWidth + scaledW + scaledSpacing > availableWidth && currentRow.isNotEmpty) {
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

            // 책장 한 칸의 베이스 높이: (책 최대 170 + 나무선반 12 + 여백 8)
            double scaledShelfHeight = (170.0 + 12.0 + 8.0) * s;
            double totalRequiredHeight = testShelves.length * scaledShelfHeight;

            if (totalRequiredHeight <= availableHeight) {
              optimalScale = s;
              optimalShelves = testShelves;
              break;
            }
          }

          // 만약 optimalShelves가 비어있다면 (너무 빽빽할 경우 최소값 보정)
          if (optimalShelves.isEmpty) {
             optimalScale = 0.2; // fallback
             // 다시 계산
              List<int> currentRow = [];
              double currentRowWidth = 0.0;
              double scaledSpacing = 1.0 * optimalScale;
              for (int i = 0; i < originalWidths.length; i++) {
                double scaledW = originalWidths[i] * optimalScale;
                if (currentRowWidth + scaledW + scaledSpacing > availableWidth && currentRow.isNotEmpty) {
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

          // 화면 하단에서부터 차곡차곡 쌓아올리기 (최신 선반이 맨 위로)
          final reversedShelves = optimalShelves.reversed.toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            child: Column(
              children: [
                // 상당 고정: Firenze 타이틀 영역
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B1B1B), // 고급스러운 버건디 뒷배경
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Firenze',
                      style: TextStyle(
                        fontFamily: 'GreatVibes', // 필기체 폰트 (Pubspec에 없으면 Fallback으로 cursive 테마 사용)
                        fontSize: 36,
                        color: Colors.white,
                        shadows: [
                          // 음각(Engraved) 효과를 위한 대비된 안쪽/바깥쪽 그림자 트릭
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
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFF7F4F0), // 벽지 색상
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end, // 가장 밑바닥 선반부터 안착
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: reversedShelves.map((shelfIndices) {
                        return _buildScaledShelf(shelfIndices, books, optimalScale);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScaledShelf(List<int> shelfIndices, List<UserBook> allBooks, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) 책들이 서 있는 공간 (최대 스케일 높이 고정)
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
                  alignment: Alignment.bottomCenter, // 바닥 기준 스케일다운
                  child: BookSpineWidget(
                    key: ValueKey(allBooks[index].isbn),
                    userBook: allBooks[index],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // 2) 나무 선반
        Container(
          width: double.infinity,
          height: 12.0 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF5A1E1E),
            borderRadius: BorderRadius.circular(4 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4 * scale,
                offset: Offset(0, 3 * scale),
              ),
            ],
          ),
          margin: EdgeInsets.only(bottom: 8.0 * scale), // 선반 사이의 수직 여백
        ),
      ],
    );
  }
}
