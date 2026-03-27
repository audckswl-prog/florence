import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../library/screens/library_stack_view.dart';
import '../../library/providers/library_providers.dart';
import '../../social/widgets/shared_reading_ticket_widget.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/user_book_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/project_member_model.dart';

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
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  // --- Mock Data Generators ---
  List<UserBook> _generateMockBooks() {
    final books = <UserBook>[];
    for (int i = 0; i < 28; i++) {
      int pageCount = 200 + Random().nextInt(400); // 200~600 pages
      books.add(UserBook(
        id: 'mock_$i',
        userId: '1',
        isbn: 'isbn_$i',
        status: 'read',
        readPages: pageCount,
        totalPages: pageCount,
        startedAt: DateTime.now().subtract(Duration(days: 30 - i)),
        finishedAt: DateTime.now().subtract(Duration(days: 28 - i)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        book: Book(
          isbn: 'isbn_$i',
          title: '피렌체 베스트 $i',
          author: '피렌체',
          publisher: '플로렌스 북스',
          pubDate: '2023-01-01',
          description: '',
          coverUrl: '',
          categoryName: '소설',
          pageCount: pageCount,
        ),
      ));
    }
    return books;
  }

  Project _generateMockProject() {
    return Project(
      id: 'onboard_proj',
      creatorId: 'user1',
      bookIsbn: '9788932036733',
      name: '고전문학 함께 읽기',
      description: '',
      status: 'active',
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now(),
      coverUrl: '',
      bookTitle: '데미안',
      bookAuthor: '헤르만 헤세',
    );
  }

  Map<String, ProjectMember> _generateMockMembers() {
    return {
      'user1': ProjectMember(
        id: '1',
        projectId: 'onboard_proj',
        userId: 'user1',
        role: 'admin',
        nickname: '레오나르도',
        profileUrl: null,
        progress: 100,
        lastReadPage: 230,
        lastReadAt: DateTime.now(),
        quote: '새는 알에서 나오려고 투쟁한다. 알은 세계이다.',
        quotePage: 154,
      ),
      'user2': ProjectMember(
        id: '2',
        projectId: 'onboard_proj',
        userId: 'user2',
        role: 'member',
        nickname: '단테',
        profileUrl: null,
        progress: 80,
        lastReadPage: 180,
        lastReadAt: DateTime.now(),
        quote: '결국 나는 내 속에서 솟아나오려는 것, 그것을 살아보려 했다.',
        quotePage: 121,
      ),
    };
  }

  // --- Page Builders ---
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.burgundy
                : AppColors.burgundy.withOpacity(0.2),
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

  Widget _buildLibraryPage() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: ClipRect(
            child: ProviderScope(
              overrides: [
                readBooksProvider.overrideWith(
                    (ref) => AsyncValue.data(_generateMockBooks())),
              ],
              child: const IgnorePointer(child: LibraryStackView()),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildTextSection('내 손안의 작은 서재',
              '자신의 서재에 다수의 책이 예쁘게 쌓여있는 모습을 한눈에 볼 수 있습니다. 실제 책 두께에 비례하여 꽂히는 책장의 성취감을 느껴보세요.'),
        ),
      ],
    );
  }

  Widget _buildTicketPage() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: SharedReadingTicketWidget(
                    project: _generateMockProject(),
                    members: _generateMockMembers().values.toList(),
                    memberProfiles: const {},
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildTextSection('함께 읽고 개성을 남기다',
              '주변 친구와 책을 함께 읽고, 각자의 개성이 담긴 감명 깊은 구절을 기록하여 세상에 하나뿐인 아름다운 빈티지 독서 티켓을 받아보세요.'),
        ),
      ],
    );
  }

  Widget _buildMemoPage() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight.withOpacity(0.3),
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
          flex: 4,
          child: _buildTextSection('인상적인 문장을 사진과 함께',
              '오래도록 기억에 남고 싶은 감명 깊었던 문장과 페이지는 메모 탭에서 깔끔한 사진 카드 형태로 정리해두실 수 있습니다.'),
        ),
      ],
    );
  }

  Widget _buildGraphPage() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.burgundy.withOpacity(0.05),
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
                          painter: _OnboardingRadarChartPainter(
                            animationValue: value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildTextSection('나의 독서 취향 발견',
              '레이더 차트 등 선호 장르와 월간 독서량을 수치로 보여주는 통계 기능을 통해 자신이 어떤 취향의 독자인지 마이페이지에서 우아하게 확인해 보세요.'),
        ),
      ],
    );
  }

  Widget _buildDocentPage() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: FlorenceLoader(),
                ),
                const SizedBox(height: 32),
                Text(
                  '피렌체의 도슨트가\\n당신을 위한 이야기를 고르고 있습니다...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: AppColors.charcoal.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildTextSection('나만의 전담 AI 도슨트',
              '피렌체 도슨트가 매력적인 책 소개 문구를 만들어 줍니다. 이 책이 집필될 당시의 흥미로운 사회적 배경과 작가에 대한 비하인드 설명을 심도 있게 제공받아보세요.'),
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
            // 앱 로고 (상단 헤더)
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
            
            // 핵심 뷰 페이저
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildLibraryPage(),
                  _buildTicketPage(),
                  _buildMemoPage(),
                  _buildGraphPage(),
                  _buildDocentPage(),
                ],
              ),
            ),

            // 하단 인디케이터 및 버튼 구역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _buildPageIndicator(),
                  const SizedBox(height: 32),
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
                        _currentPage == 4 ? '피렌체 시작하기' : '다음',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_currentPage < 4)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48), // 영역 고정
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 통계 화면용 약식 커스텀 페인터 복사본 ──
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
      ..color = AppColors.greyLight.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int level = 1; level <= 3; level++) {
      final levelRadius = radius * (level / 3);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = startAngle + angleStep * i;
        final point = Offset(center.dx + levelRadius * cos(angle), center.dy + levelRadius * sin(angle));
        if (i == 0) path.moveTo(point.dx, point.dy);
        else path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 모의 데이터 육각형
    final values = [0.8, 0.4, 0.9, 0.3, 0.6, 0.5, 0.2, 0.7];
    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final point = Offset(
        center.dx + radius * (values[i] * animationValue) * cos(angle),
        center.dy + radius * (values[i] * animationValue) * sin(angle),
      );
      if (i == 0) dataPath.moveTo(point.dx, point.dy);
      else dataPath.lineTo(point.dx, point.dy);
    }
    dataPath.close();

    canvas.drawPath(dataPath, Paint()..color = AppColors.burgundy.withOpacity(0.2)..style = PaintingStyle.fill);
    canvas.drawPath(dataPath, Paint()..color = AppColors.burgundy..style = PaintingStyle.stroke..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
