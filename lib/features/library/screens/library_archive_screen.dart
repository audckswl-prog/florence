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
    body:
    SafeArea(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF7F4F0), // 벽지 색상
        // 1. 외곽 전체를 아우르는 두꺼운 책장 프레임
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF5A1E1E),
            width: 12,
          ), // 두꺼운 원목 테두리
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 여백 없이 꽉 채우는 책장 로직을 위해 패딩 완전히 제거
            const double horizontalPadding = 0.0;
            const double verticalPadding = 0.0;

            final double availableWidth =
                constraints.maxWidth - (horizontalPadding * 2);
            final double availableHeight =
                constraints.maxHeight -
                (verticalPadding * 2) -
                80; // 80은 상단 Firenze 헤더 공간

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
              double w = ((18.0 + (pages * 0.08)) * thicknessRatio).clamp(
                14.0,
                70.0,
              );
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

              // 책장 한 칸의 베이스 높이: (책 최대 170 + 나무선반 12 + 여백 8)
              double scaledShelfHeight = (170.0 + 12.0 + 8.0) * s;
              double totalRequiredHeight =
                  testShelves.length * scaledShelfHeight;

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

            // 화면 하단에서부터 차곡차곡 쌓아올리기 (최신 선반이 맨 위로)
            final reversedShelves = optimalShelves.reversed.toList();

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  // 상당 고정: Firenze 타이틀 영역 (헤더 보드)
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5A1E1E), // 프레임과 완벽히 색을 맞춘 상단 두꺼운 나무판
                    ),
                    child: Center(
                      child: Text(
                        'Firenze',
                        style: TextStyle(
                          fontFamily:
                              'GreatVibes', // 필기체 폰트 (Pubspec에 없으면 Fallback으로 cursive 테마 사용)
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
                      color: const Color(0xFFF7F4F0), // 벽/책장 뒷배경 색상
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.end, // 가장 밑바닥 선반부터 안착
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        // 첫 선반이나 헤더 바로 아래쪽에도 자연스러운 칸막이(Divider)를 그리기 위해 여백 정리
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
              ),
            );
          },
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

        // 2) 책장 칸막이 (Divider Floor)
        // 두꺼운 원목 선반을 프레임 모서리부터 끝까지 꽉 차게 그립니다 (모서리 각지게 처리)
        Container(
          width: double.infinity,
          height: 14.0 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF5A1E1E),
            // 그림자를 더 어둡고 묵직하게 넣어서 칸막이 입체감 극대화
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: Offset(0, -2 * scale), // 선반 윗면의 어두운 그림자 (벽 안쪽으로 들어간 느낌)
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 4 * scale,
                offset: Offset(0, 4 * scale), // 선반 밑면 그림자
              ),
            ],
          ),
        ),
      ],
    );
  }
}
