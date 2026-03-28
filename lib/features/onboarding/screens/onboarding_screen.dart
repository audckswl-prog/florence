import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../social/widgets/shared_reading_ticket_widget.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';
import '../../library/widgets/book_spine_widget.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/user_book_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  // --- Mock Data ---
  Project _generateMockProject() {
    return Project(
      id: 'onboard_proj',
      ownerId: 'user1',
      isbn: '9788932036733',
      name: '고전문학 함께 읽기',
      status: 'in_progress',
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now(),
    );
  }

  List<ProjectMember> _generateMockMembers() {
    return [
      ProjectMember(
        id: '1',
        projectId: 'onboard_proj',
        userId: 'user1',
        role: 'owner',
        readingStatus: 'completed',
        aiQuestionCount: 0,
        nickname: '레오나르도',
        quote: '새는 알에서 나오려고 투쟁한다. 알은 세계이다.',
        joinedAt: DateTime.now(),
        readPages: 230,
        totalPages: 230,
      ),
      ProjectMember(
        id: '2',
        projectId: 'onboard_proj',
        userId: 'user2',
        role: 'member',
        readingStatus: 'reading',
        aiQuestionCount: 0,
        nickname: '단테',
        quote: '결국 나는 내 속에서 솟아나오려는 것, 그것을 살아보려 했다.',
        joinedAt: DateTime.now(),
        readPages: 180,
        totalPages: 230,
      ),
    ];
  }

  List<UserBook> _generateMockBooks() {
    final books = <UserBook>[];
    for (int i = 0; i < 28; i++) {
      int pageCount = 200 + Random(i).nextInt(400);
      books.add(UserBook(
        id: 'mock_$i',
        userId: '1',
        isbn: 'isbn_$i',
        status: 'read',
        readPages: pageCount,
        totalPages: pageCount,
        startedAt: DateTime.now().subtract(Duration(days: 30 - i)),
        finishedAt: DateTime.now().subtract(Duration(days: 28 - i)),
        book: Book(
          isbn: 'isbn_$i',
          title: '피렌체 베스트 $i',
          author: '피렌체',
          publisher: '플로렌스 북스',
          pubDate: '2023-01-01',
          description: '',
          coverUrl: '',
          categoryName: '소설',
          link: '',
          pageCount: pageCount,
        ),
      ));
    }
    return books;
  }

  // --- Page Builders ---
  Widget _buildWelcomePage() {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 64, color: AppColors.burgundy),
                const SizedBox(height: 24),
                Text(
                  'Florence',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildTextSection(
              '피렌체에 오신 것을 환영합니다',
              '피렌체를 통해 편리하게 독서를 기록해보세요.\n자랑하는 것 같아서 맘 편히 독서경험을 공유하지 못했던 분들, 혹은 친구와 함께 독서하고 싶은 분들, 아울러 독서를 사랑하는 분들께 피렌체를 전합니다.'),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.burgundy
                : AppColors.burgundy.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildTextSection(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 1. 서재 페이지 (BookSpineWidget 직접 사용)
  Widget _buildLibraryPage() {
    final mockBooks = _generateMockBooks();
    // 선반으로 묶기
    final double maxShelfWidth = MediaQuery.of(context).size.width - 32;
    final List<List<UserBook>> shelves = [];
    List<UserBook> currentRow = [];
    double currentRowWidth = 0;
    for (var ub in mockBooks) {
      int pages = ub.book.pageCount;
      if (pages == 0) pages = 300;
      double bookWidth = ((18.0 + (pages * 0.08)) * 1.0).clamp(14.0, 70.0);
      if (currentRowWidth + bookWidth + 1 > maxShelfWidth && currentRow.isNotEmpty) {
        shelves.add(currentRow);
        currentRow = [];
        currentRowWidth = 0;
      }
      currentRow.add(ub);
      currentRowWidth += bookWidth + 1;
    }
    if (currentRow.isNotEmpty) shelves.add(currentRow);

    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 총 권수 헤더
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Text(
                    '총 ${mockBooks.length}권',
                    style: const TextStyle(
                      color: AppColors.burgundy,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                Container(height: 1, color: AppColors.burgundy),
                const SizedBox(height: 8),
                // 선반들
                Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shelves.reversed.toList().length.clamp(0, 3),
                    itemBuilder: (context, index) {
                      final shelfBooks = shelves.reversed.toList()[index];
                      return Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: shelfBooks
                                  .map((b) => BookSpineWidget(key: ValueKey(b.isbn), userBook: b))
                                  .toList(),
                            ),
                          ),
                          Container(
                            height: 10,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A1E1E),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildTextSection('내 손안의 작은 서재',
              '읽은 책이 실제 두께에 비례하여 빼곡하게 꽂히는 나만의 책장을 만들어보세요.'),
        ),
      ],
    );
  }

  // 2. 독서 티켓 페이지
  Widget _buildTicketPage() {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: SharedReadingTicketWidget(
                    project: _generateMockProject(),
                    members: _generateMockMembers(),
                    memberProfiles: <String, Profile>{},
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildTextSection('함께 읽고 개성을 남기다',
              '책을 친구와 함께 읽고, 개성이 담긴 독서 티켓을 받아보세요!'),
        ),
      ],
    );
  }

  // 3. 메모 페이지
  Widget _buildMemoPage() {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.menu_book, size: 64, color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.format_quote, color: AppColors.burgundy),
                  const SizedBox(height: 8),
                  const Text(
                    '결국 나는 내 속에서 솟아나오려는 것, 그것을 살아보려 했다. 왜 그것이 그토록 어려웠을까.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      height: 1.6,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'p.121',
                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildTextSection('인상적인 문장을 사진과 함께',
              '감명 깊었던 문장과 페이지는 메모 탭에서 깔끔한 사진 카드 형태로 정리해두세요.'),
        ),
      ],
    );
  }

  // 4. 통계 페이지
  Widget _buildGraphPage() {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width - 64,
              height: MediaQuery.of(context).size.width - 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.burgundy.withValues(alpha: 0.05),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: _OnboardingRadarChartPainter(animationValue: value),
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildTextSection('나의 독서 취향 발견',
              '레이더 차트와 월간 독서량 통계로 나의 독서 취향을 우아하게 확인해보세요.'),
        ),
      ],
    );
  }

  // 5. 도슨트 페이지
  Widget _buildDocentPage() {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 120,
                  height: 120,
                  child: FlorenceLoader(),
                ),
                const SizedBox(height: 32),
                Text(
                  '피렌체의 도슨트가\n당신을 위한 이야기를 고르고 있습니다...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: AppColors.charcoal.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildTextSection('나만의 전담 AI 도슨트',
              '피렌체 도슨트가 책의 시대적 배경과 작가에 대한 비하인드 설명을 심도 있게 제공합니다.'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: Text(
                'Florence',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(),
                  _buildLibraryPage(),
                  _buildTicketPage(),
                  _buildMemoPage(),
                  _buildGraphPage(),
                  _buildDocentPage(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, max(16, MediaQuery.of(context).padding.bottom + 16)),
              child: Column(
                children: [
                  _buildPageIndicator(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.burgundy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == 5 ? '피렌체 시작하기' : '다음',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 통계 레이더 차트 ──
class _OnboardingRadarChartPainter extends CustomPainter {
  final double animationValue;
  _OnboardingRadarChartPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;
    const sides = 8;
    const angleStep = (2 * pi) / sides;
    const startAngle = -pi / 2;

    final gridPaint = Paint()
      ..color = AppColors.greyLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int level = 1; level <= 3; level++) {
      final levelRadius = radius * (level / 3);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = startAngle + angleStep * i;
        final point = Offset(center.dx + levelRadius * cos(angle), center.dy + levelRadius * sin(angle));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final values = [0.8, 0.4, 0.9, 0.3, 0.6, 0.5, 0.2, 0.7];
    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final point = Offset(
        center.dx + radius * (values[i] * animationValue) * cos(angle),
        center.dy + radius * (values[i] * animationValue) * sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, Paint()..color = AppColors.burgundy.withValues(alpha: 0.2)..style = PaintingStyle.fill);
    canvas.drawPath(dataPath, Paint()..color = AppColors.burgundy..style = PaintingStyle.stroke..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
