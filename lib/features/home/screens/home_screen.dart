import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
// import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../library/screens/book_search_delegate.dart';
import '../../library/screens/library_stack_view.dart';
import '../../library/providers/library_providers.dart';
import '../../library/providers/book_providers.dart';
import '../../social/providers/social_providers.dart';
import '../widgets/shared_reading_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        toolbarHeight: 70,
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _tabController.index == 0
              ? GestureDetector(
                  onTap: () {
                    showSearch(
                      context: context,
                      delegate: BookSearchDelegate(ref),
                    );
                  },
                  child: Container(
                    height: 44,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.burgundy.withOpacity(0.1),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.burgundy.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppColors.burgundy,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '제목, 저자 또는 ISBN으로 검색',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.grey.withOpacity(0.7),
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SharedReadingAppBarTitle(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 8),
            child: TabBar(
              controller: _tabController,
              tabAlignment: TabAlignment.center,
              isScrollable: true,
              indicator: const CircleTabIndicator(
                color: AppColors.burgundy,
                radius: 4,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorPadding: const EdgeInsets.only(bottom: -4),
              dividerColor: Colors.transparent,
              labelColor: AppColors.black,
              unselectedLabelColor: AppColors.grey,
              labelPadding: const EdgeInsets.symmetric(horizontal: 24),

              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: 'Pretendard',
              ),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: '내 서재'),
                Tab(text: '함께한 독서'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_MyLibraryTab(), _SharedReadingTab()],
      ),
    );
  }
}

class _MyLibraryTab extends ConsumerWidget {
  const _MyLibraryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // ── 상단: 검색바 제거됨 (AppBar로 이동) ──

        // ── 하단: 책 스택 (아래에서 위로 쌓임) ──
        const Expanded(child: LibraryStackView()),
      ],
    );
  }
}

class _SharedReadingTab extends ConsumerWidget {
  const _SharedReadingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(myProjectsWithMembersProvider);
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Search, Friends, and Notifications Header
          const SharedReadingHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: projectsAsync.when(
              data: (projectsWithMembers) {
                if (projectsWithMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 64,
                          color: AppColors.greyLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '참여 중인 모임이 없습니다.\n새로운 독서 모임을 만들어보세요!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.grey, height: 1.5),
                        ),
                      ],
                    ),
                  );
                }

                // 모든 멤버가 독서 진도 100% 달성(status == 'completed') + 독서 티켓 100% 작성(quote, drawingUrl)
                final completed = projectsWithMembers.where((p) {
                  final isProjectCompleted = p.project.status == 'completed';
                  final areAllTicketsReady = p.members.every((m) =>
                      m.quote != null && m.quote!.isNotEmpty &&
                      m.drawingUrl != null && m.drawingUrl!.isNotEmpty);
                  return isProjectCompleted && areAllTicketsReady;
                }).toList();

                final active = projectsWithMembers.where((p) {
                  final isProjectCompleted = p.project.status == 'completed';
                  final areAllTicketsReady = p.members.every((m) =>
                      m.quote != null && m.quote!.isNotEmpty &&
                      m.drawingUrl != null && m.drawingUrl!.isNotEmpty);
                  if (isProjectCompleted && areAllTicketsReady) return false;

                  // 1. 독서 진행 중(in_progress) && 마감 기한이 지난 경우 제외
                  if (p.project.status == 'in_progress' && p.project.endDate != null) {
                    if (DateTime.now().isAfter(p.project.endDate!)) {
                      return false; // 만료됨
                    }
                  }

                  // 2. 책 선택 대기 중(pending_books) && 초대 수락 후 2일(48시간)이 지난 경우 제외
                  if (p.project.status == 'pending_books' && p.members.length >= 2) {
                    final latestJoined = p.members
                        .map((m) => m.joinedAt)
                        .reduce((a, b) => a.isAfter(b) ? a : b);
                    if (DateTime.now().difference(latestJoined).inHours >= 48) {
                      return false; // 만료됨
                    }
                  }

                  return true;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  children: [
                    // ── 진행 중인 프로젝트 ──
                    if (active.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          '진행 중',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      // 가로 스크롤을 위한 고정 높이 컨테이너
                      SizedBox(
                        height: 280, // 세로형 카드를 위한 높이 지정
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: active.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 16), // 카드 사이 간격
                          // 카드를 자를 때 패딩이 잘리는 것을 방지하기 위한 여백 추가: top, bottom, right 그림자 영역을 위해 여유분
                          padding: const EdgeInsets.only(right: 20, bottom: 20, top: 8, left: 4),
                          itemBuilder: (context, index) {
                            return _buildActiveProjectCard(context, active[index]);
                          },
                        ),
                      ),
                    ],

                    // ── 완료된 프로젝트 ──
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '완독',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 480, // Height for the mini tickets
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: completed.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            return _buildCompletedMiniTicket(context, completed[index], index);
                          },
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                  ],
                );
              },
              loading: () => const Center(child: FlorenceLoader()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProjectCard(BuildContext context, ProjectWithMembers pw) {
    final project = pw.project;
    final coverUrl = pw.firstBookCover;
    final bookTitle = pw.firstBookTitle;
    
    // 화면 너비의 특정 비율로 가로폭 설정 (예: 42%)
    final cardWidth = MediaQuery.of(context).size.width * 0.42;

    return GestureDetector(
      onTap: () {
        context.push('/home/social/detail/${project.id}', extra: project);
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.02)),
        ),
        clipBehavior: Clip.antiAlias, // 자식 이미지가 둥근 모서리를 넘지 않도록
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: Book Cover (Expanded to take up top portion)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.ivory,
                ),
                child: coverUrl != null && coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: CustomPaint(
                            size: const Size(48, 48),
                            painter: FlorenceDomePainter(
                              progress: 1.0,
                              color: AppColors.greyLight.withOpacity(0.8),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: CustomPaint(
                          size: const Size(48, 48),
                          painter: FlorenceDomePainter(
                            progress: 1.0,
                            color: AppColors.greyLight.withOpacity(0.8),
                          ),
                        ),
                      ),
              ),
            ),
            
            // Bottom: Info Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final myId = Supabase.instance.client.auth.currentUser?.id;
                      final others = pw.members.where((m) => m.userId != myId).toList();
                      final titleText = others.isNotEmpty 
                          ? '${others.first.nickname ?? "친구"} 님과 읽기'
                          : project.name;
                      return Text(
                        titleText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // 세로형 카드에 맞춰 폰트 크기 약간 감소
                          color: AppColors.black,
                          fontFamily: 'Pretendard',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                  ),
                  if (bookTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.grey.withOpacity(0.9),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Progress Bar & Status Section
                  Builder(
                    builder: (context) {
                      double progress = 0.5; // Default mockup
                      String remainingText = '2주 남음'; // Default mockup

                      if (project.startDate != null && project.endDate != null) {
                        final total = project.endDate!.difference(project.startDate!).inDays;
                        final current = DateTime.now().difference(project.startDate!).inDays;
                        if (total > 0) {
                          progress = (current / total).clamp(0.0, 1.0);
                        }
                        final remaining = project.endDate!.difference(DateTime.now()).inDays;
                        if (remaining >= 0) {
                          remainingText = remaining > 14 ? 'D-$remaining' : '${(remaining / 7).ceil()}주 남음';
                          if (remaining <= 14 && remaining % 7 != 0) {
                            remainingText = 'D-$remaining';
                          } else if (remaining == 14) {
                            remainingText = '2주 남음';
                          }
                        } else {
                          remainingText = '마감됨';
                          progress = 1.0;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                remainingText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.burgundy,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ivory,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  project.status == 'in_progress'
                                      ? '진행 중'
                                      : project.status == 'pending_books'
                                      ? '도서 선정'
                                      : '진행 중',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.burgundy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.greyLight.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.burgundy),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedMiniTicket(BuildContext context, ProjectWithMembers pw, int index) {
    final project = pw.project;
    final coverUrl = pw.firstBookCover;
    
    // Fake the nationality and year for the UI
    final nationalityCode = 'US';
    final publicationYear = '2011';
    final bookTitle = pw.firstBookTitle ?? 'Unknown Title';
    
    // The exact dimensions and proportions of the widget in the screenshot
    const double ticketWidth = 260.0;
    const double ticketHeight = 460.0;
    const double topCutY = 86.0;
    const double bottomCutY = 80.0;

    return GestureDetector(
      onTap: () {
        // [임시 테스트용] 완료된 카드 클릭 시에도 영수증 말고 상세 화면으로 진입하게 해서 '티켓 다시 만들기' 버튼을 누를 수 있도록 함.
        context.push('/home/social/detail/${project.id}');
        
        /* 
        context.push('/home/social/detail/${project.id}/receipt', extra: {
          'project': project,
          'rate': 1.0,
        });
        */
      },
      child: Container(
        width: ticketWidth,
        height: ticketHeight,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipPath(
          clipper: TicketClipper(topCutoutY: topCutY, bottomCutoutY: bottomCutY),
          child: ColoredBox(
            color: const Color(0xFFF0F0F0), // Paper color
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── TOP: Barcode section ──
                SizedBox(
                  height: topCutY,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: SizedBox(
                          height: 36,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(40, (i) {
                              final w = i % 4 == 0 ? 3 : (i % 3 == 0 ? 1 : 2);
                              return Container(
                                width: w.toDouble(),
                                color: AppColors.charcoal,
                              );
                            }),
                          ),
                        ),
                      ),
                      // Dashed line
                      SizedBox(
                        height: 1,
                        child: LayoutBuilder(
                          builder: (_, constraints) {
                            const dashW = 6.0, gap = 4.0;
                            final count = (constraints.maxWidth / (dashW + gap)).floor();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                count,
                                (_) => const SizedBox(
                                  width: dashW,
                                  height: 1,
                                  child: ColoredBox(color: AppColors.grey),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ── MIDDLE: Content section ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Flight icon & flag
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                bookTitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Transform.rotate(
                                      angle: 3.14159 / 4,
                                      child: const Icon(Icons.flight, size: 16),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'G A T E',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Dummy flag image
                                Container(
                                  width: 24,
                                  height: 14,
                                  color: Colors.red.withOpacity(0.5),
                                  // In real app, you can use flag package
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '미국, $publicationYear년',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Book Cover
                        Center(
                          child: Container(
                            width: 100,
                            height: 145,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: coverUrl != null && coverUrl.isNotEmpty
                                ? Image.network(coverUrl, fit: BoxFit.cover)
                                : const SizedBox.shrink(),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Page or identifier
                        const Text(
                          'P.???',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.charcoal,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Quote
                        const Expanded(
                          child: Text(
                            '"행복의 극대화, 자유의 존중, 그리고 미덕의 배양. 정의에 대한 이 세 가지 접근 방식은 서로 다른 방식으로 정의를 바라보게 한다."',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.5,
                              color: AppColors.charcoal,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── BOTTOM: Firenze logo & button ──
                SizedBox(
                  height: bottomCutY,
                  child: Column(
                    children: [
                      // Dashed line
                      SizedBox(
                        height: 1,
                        child: LayoutBuilder(
                          builder: (_, constraints) {
                            const dashW = 6.0, gap = 4.0;
                            final count = (constraints.maxWidth / (dashW + gap)).floor();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                count,
                                (_) => const SizedBox(
                                  width: dashW,
                                  height: 1,
                                  child: ColoredBox(color: AppColors.grey),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Firenze',
                                style: TextStyle(
                                  fontFamily: 'GreatVibes',
                                  fontSize: 28,
                                  color: AppColors.burgundy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '독서앱 설치하기',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircleTabIndicator extends Decoration {
  final Color color;
  final double radius;

  const CircleTabIndicator({required this.color, required this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CirclePainter(color: color, radius: radius);
  }
}

class _CirclePainter extends BoxPainter {
  final Color color;
  final double radius;

  _CirclePainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    Paint _paint = Paint();
    _paint.color = color;
    _paint.isAntiAlias = true;
    final Offset circleOffset = Offset(
      configuration.size!.width / 2 - radius / 2,
      configuration.size!.height - radius,
    );
    canvas.drawCircle(offset + circleOffset, radius, _paint);
  }
}

// ── Ticket-shaped clip (half-circle notches on sides) ────────────────
class TicketClipper extends CustomClipper<Path> {
  final double topCutoutY;
  final double bottomCutoutY;

  const TicketClipper({required this.topCutoutY, required this.bottomCutoutY});

  @override
  Path getClip(Size size) {
    const r = 10.0;
    final p = Path();

    p.moveTo(0, 0);
    p.lineTo(size.width, 0);

    // right top notch
    p.lineTo(size.width, topCutoutY - r);
    p.arcTo(
      Rect.fromCircle(center: Offset(size.width, topCutoutY), radius: r),
      -3.14159 / 2,
      -3.14159,
      false,
    );

    // right bottom notch
    p.lineTo(size.width, size.height - bottomCutoutY - r);
    p.arcTo(
      Rect.fromCircle(
        center: Offset(size.width, size.height - bottomCutoutY),
        radius: r,
      ),
      -3.14159 / 2,
      -3.14159,
      false,
    );

    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);

    // left bottom notch
    p.lineTo(0, size.height - bottomCutoutY + r);
    p.arcTo(
      Rect.fromCircle(
        center: Offset(0, size.height - bottomCutoutY),
        radius: r,
      ),
      3.14159 / 2,
      -3.14159,
      false,
    );

    // left top notch
    p.lineTo(0, topCutoutY + r);
    p.arcTo(
      Rect.fromCircle(center: Offset(0, topCutoutY), radius: r),
      3.14159 / 2,
      -3.14159,
      false,
    );

    p.close();
    return p;
  }

  @override
  bool shouldReclip(TicketClipper old) =>
      old.topCutoutY != topCutoutY || old.bottomCutoutY != bottomCutoutY;
}
