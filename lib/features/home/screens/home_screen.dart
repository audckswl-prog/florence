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

                // 완료된 프로젝트를 상단, 진행 중을 하단에 표시
                final completed = projectsWithMembers
                    .where((p) => p.project.status == 'completed')
                    .toList();
                final active = projectsWithMembers
                    .where((p) => p.project.status != 'completed')
                    .toList();

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
                      ...active.map(
                        (pw) => _buildActiveProjectCard(context, pw),
                      ),
                    ],

                    // ── 완료된 프로젝트 ──
                    if (completed.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.only(
                          top: active.isNotEmpty ? 24 : 0,
                          bottom: 12,
                        ),
                        child: const Text(
                          '완독',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      ...completed.map(
                        (pw) => _buildCompletedTicketCard(context, pw),
                      ),
                    ],
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          context.push('/home/social/detail/${project.id}', extra: project);
        },
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Book Cover
                Container(
                  width: 65,
                  height: 95,
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.menu_book,
                              color: AppColors.greyLight,
                              size: 28,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.menu_book,
                            color: AppColors.greyLight,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(width: 16),

                // Right: Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.black,
                          fontFamily: 'Pretendard',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (bookTitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.grey.withOpacity(0.9),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Status badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ivory,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people_alt,
                                  size: 12,
                                  color: AppColors.burgundy,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  project.status == 'in_progress'
                                      ? '진행 중'
                                      : project.status == 'pending_books'
                                      ? '책 선택 중'
                                      : project.status == 'completed'
                                      ? '완독'
                                      : '진행 중',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.burgundy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '상세보기 >',
                            style: TextStyle(
                              color: AppColors.greyLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
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

  Widget _buildCompletedTicketCard(BuildContext context, ProjectWithMembers pw) {
    final project = pw.project;
    final coverUrl = pw.firstBookCover;
    final bookTitle = pw.firstBookTitle;
    final memberCount = pw.members.length;

    // Fixed height for the inline ticket
    final double ticketHeight = 360.0;
    final double topH = 80.0;
    final double botH = 80.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GestureDetector(
        onTap: () {
          // completed 상태면 상세 화면의 티켓(receipt) 뷰로 바로 이동
          context.push('/home/social/detail/${project.id}/receipt', extra: {
            'project': project,
            'rate': 1.0, // 완독이므로 100%
          });
        },
        child: Container(
          height: ticketHeight,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipPath(
            clipper: TicketClipper(topCutoutY: topH, bottomCutoutY: botH),
            child: ColoredBox(
              color: const Color(0xFFF0F0F0), // Original ticket bg color
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── TOP (barcode) ──────────────────────────────────────
                  SizedBox(
                    height: topH,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 18,
                            right: 18,
                            bottom: 16,
                          ),
                          child: SizedBox(
                            height: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(36, (i) {
                                final w = i % 3 == 0 ? 3 : (i % 2 == 0 ? 1 : 2);
                                return Container(
                                  width: w.toDouble(),
                                  color: AppColors.charcoal,
                                );
                              }),
                            ),
                          ),
                        ),
                        // Replace DashedLine widget with simple Container + CustomPaint if DashedLine isn't used globally,
                        // or just use a simple dashed line approach
                        SizedBox(
                          height: 1,
                          child: LayoutBuilder(
                            builder: (_, constraints) {
                              const dashW = 7.0, gap = 5.0;
                              final count = (constraints.maxWidth / (dashW + gap)).floor();
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  count,
                                  (_) => SizedBox(
                                    width: dashW,
                                    height: 1,
                                    child: ColoredBox(color: AppColors.charcoal.withOpacity(0.8)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── MIDDLE (content) ──────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 18,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Book Cover
                          Expanded(
                            flex: 4,
                            child: AspectRatio(
                              aspectRatio: 1 / 1.45,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: coverUrl != null && coverUrl.isNotEmpty
                                      ? Image.network(
                                          coverUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(color: AppColors.ivory),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Right: Content Details
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // GATE & Flight Icon
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Transform.rotate(
                                          angle: 3.14159 / 4,
                                          child: const Icon(
                                            Icons.flight,
                                            size: 20,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'SHARED',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.0,
                                            color: AppColors.charcoal,
                                            fontFamily: 'Courier',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Project Name
                                Text(
                                  project.name,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.charcoal,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                
                                // Book Title
                                if (bookTitle != null)
                                  Text(
                                    bookTitle,
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.charcoal.withOpacity(0.8),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                
                                const Spacer(),
                                
                                // Member count
                                Row(
                                  children: [
                                    const Icon(Icons.group, size: 14, color: AppColors.charcoal),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$memberCount Members',
                                      style: const TextStyle(
                                        color: AppColors.charcoal,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── BOTTOM (Firenze) ─────────────────────────
                  SizedBox(
                    height: botH,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 1,
                          child: LayoutBuilder(
                            builder: (_, constraints) {
                              const dashW = 7.0, gap = 5.0;
                              final count = (constraints.maxWidth / (dashW + gap)).floor();
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  count,
                                  (_) => SizedBox(
                                    width: dashW,
                                    height: 1,
                                    child: ColoredBox(color: AppColors.charcoal.withOpacity(0.8)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
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
