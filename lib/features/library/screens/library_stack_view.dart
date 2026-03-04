import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/florence_loader.dart';
import '../providers/library_providers.dart';
import '../widgets/book_spine_widget.dart';
import '../screens/book_search_delegate.dart';
import '../screens/library_archive_screen.dart';
import '../../../data/models/user_book_model.dart';

class LibraryStackView extends ConsumerWidget {
  const LibraryStackView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(readBooksProvider);
    final books = booksAsync.asData?.value;
    final isLoading =
        booksAsync.isLoading || (!booksAsync.hasValue && !booksAsync.hasError);

    Widget body;
    if (booksAsync.hasError) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            '데이터를 불러오는데 실패했습니다.',
            style: TextStyle(color: AppColors.burgundy.withOpacity(0.7)),
          ),
        ),
      );
    } else if (books == null && !isLoading) {
      body = const SizedBox.shrink();
    } else if (books != null && books.isEmpty) {
      body = EmptyStateWidget(
        icon: Icons.menu_book_rounded,
        title: '서재가 비어있어요',
        subtitle: '읽은 책을 추가하여\n나만의 독서 기록을 쌓아보세요.',
        actionLabel: '책 추가하기',
        onAction: () {
          showSearch(context: context, delegate: BookSearchDelegate(ref));
        },
      );
    } else if (books != null) {
      // 가장 오래된 책이 맨 아래(네비바 근처), 최신 책이 맨 위
      // 날짜 오름차순 정렬 (Oldest -> Newest)
      final displayBooks = books.toList()
        ..sort((a, b) {
          final aDate = a.finishedAt ?? a.startedAt ?? DateTime(2000);
          final bDate = b.finishedAt ?? b.startedAt ?? DateTime(2000);
          return aDate.compareTo(bDate);
        });

      body = Column(
        children: [
          // 상단 총 권수 헤더 (사진 비율 참고 적용)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(
              top: 24.0,
              bottom: 0.0,
            ), // 책 윗부분에 거의 닿도록 아래 마진 제거
            child: Column(
              children: [
                // 1. 숫자 텍스트 (가운데 정렬) 및 우측 아카이브 아이콘
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 중앙 텍스트
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          '총 ${books.length}권',
                          style: const TextStyle(
                            color: AppColors.burgundy,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // 우측 아이콘
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    LibraryArchiveScreen(books: displayBooks),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 왼쪽 세로로 긴 직사각형
                                  Container(
                                    width: 8,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.burgundy, width: 1.5),
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                  // 오른쪽 위아래 두 개의 가로 직사각형
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.burgundy, width: 1.5),
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                      Container(
                                        width: 10,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.burgundy, width: 1.5),
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0), // 숫자와 라인 사이의 간격
                // 2. 1px 가로선 (양옆 패딩 24.0을 주어 아래쪽 붉은 선반과 가로 너비를 100% 동일하게 일치)
                Padding(
                  // 선반이 화면 양끝에서 24만큼 떨어져서 시작하므로 패딩 24.0 적용
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 1.0, // 1px 두께
                    color: AppColors.burgundy, // 선반과 똑같은 버건디 라인
                  ),
                ),
              ],
            ),
          ),
          // 스크롤 가능한 책장 영역 (위쪽 스크롤)
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 최대 가용 너비 (양옆 패딩 24 * 2 = 48 제외한 공간에서 75%만 책장으로 사용)
                // 이렇게 함으로써 오른쪽에 자연스러운 여백이 남게 만듭니다.
                final double maxShelfWidth =
                    (constraints.maxWidth - 48.0) * 0.75;

                // 책들을 선반 단위로 묶기 (아래 선반부터 윗 선반으로)
                // 현재 코드로는 Oldest부터 순서대로 묶음
                final List<List<UserBook>> shelves = [];
                List<UserBook> currentRow = [];
                double currentRowWidth = 0.0;

                // 책과 책 사이의 간격
                const double spacing = 1.0;

                for (var book in displayBooks) {
                  double bookWidth = 0.0;
                  int pages = book.book.pageCount;
                  if (pages == 0) {
                    final random = Random(book.isbn.hashCode);
                    pages = 200 + random.nextInt(400);
                  }
                  final int readPages = book.readPages;
                  final int totalPages = book.totalPages ?? pages;
                  double thicknessRatio = 1.0;
                  if (readPages > 0 &&
                      totalPages > 0 &&
                      readPages <= totalPages) {
                    thicknessRatio = readPages / totalPages;
                  }

                  // 방금 스케일을 복구한 가장 큰 사이즈 비율로 다시 맞춤
                  bookWidth = ((18.0 + (pages * 0.08)) * thicknessRatio).clamp(
                    14.0,
                    70.0,
                  );

                  if (currentRowWidth + bookWidth + spacing > maxShelfWidth &&
                      currentRow.isNotEmpty) {
                    shelves.add(currentRow);
                    currentRow = [];
                    currentRowWidth = 0.0;
                  }
                  currentRow.add(book);
                  currentRowWidth += bookWidth + spacing;
                }
                if (currentRow.isNotEmpty) {
                  shelves.add(currentRow);
                }

                // shelves는 [1선반(가장 오래된 책들), 2선반, ... , 가장 최근 선반]
                // 앱 진입 시 가장 최신 선반(예: 6, 5선반)이 화면 위쪽에 보이도록 배열을 뒤집습니다.
                // 즉, [6선반, 5선반, 4선반...] 순서
                final reversedShelves = shelves.reversed.toList();

                // 고정된 선반 컴포넌트의 총 높이 (책을 담는 최대 공간 170 + 나무 바닥 12 = 182)
                const double shelfHeight = 182.0;
                // 리스트 최상단(가로선 바로 아래)과 첫 번째 선반 사이의 고정 시작 여백
                const double topPadding = 24.0;
                // 화면 가장 밑바닥(하단바)과 두 번째 선반의 바닥이 띄워져야 할 최종 목표 여백
                const double bottomTargetGap = 12.0;

                // 기기 화면 높이(constraints.maxHeight) 내에서 2개의 선반이 완벽하게 12px 간격으로 하단에 배치되기 위한 동적 간격(황금비율)을 계산합니다.
                double dynamicGap =
                    constraints.maxHeight -
                    topPadding -
                    (shelfHeight * 2) -
                    bottomTargetGap;
                if (dynamicGap < 24.0) {
                  dynamicGap =
                      24.0; // 세로로 매우 짧은 화면일 경우 아이템이 겹치지 않도록 최소 24px 간격을 보장합니다.
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: topPadding,
                    bottom: 0,
                    left: 24,
                    right: 24,
                  ),
                  itemCount: reversedShelves.length,
                  itemBuilder: (context, index) {
                    final shelfBooks = reversedShelves[index];
                    final isBottomMostShelf =
                        index == reversedShelves.length - 1;

                    // 마지막(가장 오래된 맨 밑바닥) 선반은 네비바와 12px, 그 외 모든 일반 선반들은 기기 화면비율에 맞춘 간격(dynamicGap) 적용
                    final margin = isBottomMostShelf ? 12.0 : dynamicGap;

                    return _buildShelfRow(shelfBooks, bottomMargin: margin);
                  },
                );
              },
            ),
          ),
        ],
      );
    } else {
      body = const SizedBox.shrink();
    }

    return FlorenceLoadingOverlay(isLoading: isLoading, child: body);
  }

  Widget _buildShelfRow(
    List<UserBook> shelfBooks, {
    double bottomMargin = 24.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) 책들이 서 있는 메인 공간 (높이 170px 고정)
        // 최대 170px 높이의 틀 안에서 어떤 높이의 책(150~170)이 오든 바닥(목재 선반 위)에 닿게 정렬
        SizedBox(
          height: 170.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: shelfBooks
                  .map(
                    (b) => BookSpineWidget(key: ValueKey(b.isbn), userBook: b),
                  )
                  .toList(),
            ),
          ),
        ),

        // 2) 원래 색상의 플로팅 선반 받침대 (버건디 톤)
        Container(
          height: 12, // 선반 두께
          decoration: BoxDecoration(
            color: const Color(0xFF5A1E1E), // 원래 색상 복구
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // 원래 width: double.infinity 였으나, 양 옆을 가로선과 똑같이 비우기 위해 24 마진을 추가
          margin: EdgeInsets.only(left: 24.0, right: 24.0, bottom: bottomMargin),
        ),
      ],
    );
  }
}
