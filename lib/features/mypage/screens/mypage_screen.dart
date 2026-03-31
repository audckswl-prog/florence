import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../core/utils/florence_toast.dart';

import '../../library/providers/library_providers.dart';
import '../../library/providers/book_providers.dart';
import '../../social/providers/social_providers.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen>
    with TickerProviderStateMixin {
  bool _isUploading = false;
  late AnimationController _barAnimController;
  late Animation<double> _barAnimation;
  late AnimationController _radarAnimController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _barAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnimation = CurvedAnimation(
      parent: _barAnimController,
      curve: Curves.easeOutCubic,
    );
    _radarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _radarAnimation = CurvedAnimation(
      parent: _radarAnimController,
      curve: Curves.easeOutBack,
    );
    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _radarAnimController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _barAnimController.forward();
    });
  }

  @override
  void dispose() {
    _barAnimController.dispose();
    _radarAnimController.dispose();
    super.dispose();
  }

  // Fixed 8 genre categories
  static const List<String> _allGenres = [
    '문학',
    '인문/사회/역사',
    '경제경영',
    '자기계발',
    '과학/IT',
    '유아/학습',
    '라이프/예술',
    '기타',
  ];

  String _getSimpleCategory(String rawCategory) {
    // 1. 문학 (소설/시/에세이)
    if (rawCategory.contains('소설') ||
        rawCategory.contains('에세이') ||
        rawCategory.contains('시') ||
        rawCategory.contains('희곡')) return '문학';
    // 2. 경제경영
    if (rawCategory.contains('경제') ||
        rawCategory.contains('경영') ||
        rawCategory.contains('투자') ||
        rawCategory.contains('재테크') ||
        rawCategory.contains('마케팅')) return '경제경영';
    // 3. 자기계발
    if (rawCategory.contains('자기계발') ||
        rawCategory.contains('성공') ||
        rawCategory.contains('처세') ||
        rawCategory.contains('인간관계')) return '자기계발';
    // 4. 인문/사회/역사
    if (rawCategory.contains('인문') ||
        rawCategory.contains('사회') ||
        rawCategory.contains('역사') ||
        rawCategory.contains('철학') ||
        rawCategory.contains('심리')) return '인문/사회/역사';
    // 5. 과학/IT/컴퓨터
    if (rawCategory.contains('과학') ||
        rawCategory.contains('수학') ||
        rawCategory.contains('IT') ||
        rawCategory.contains('컴퓨터') ||
        rawCategory.contains('프로그래밍') ||
        rawCategory.contains('모바일')) return '과학/IT';
    // 6. 라이프/예술/취미
    if (rawCategory.contains('건강') ||
        rawCategory.contains('취미') ||
        rawCategory.contains('요리') ||
        rawCategory.contains('여행') ||
        rawCategory.contains('예술') ||
        rawCategory.contains('스포츠') ||
        rawCategory.contains('대중문화') ||
        rawCategory.contains('가정') ||
        rawCategory.contains('살림')) return '라이프/예술';
    // 7. 유아/학습/외국어
    if (rawCategory.contains('유아') ||
        rawCategory.contains('어린이') ||
        rawCategory.contains('청소년') ||
        rawCategory.contains('외국어') ||
        rawCategory.contains('사전') ||
        rawCategory.contains('자격증') ||
        rawCategory.contains('수험서')) return '유아/학습';
    // 8. 기타 (종교, 만화, 잡지, 고전 등)
    return '기타';
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      await ref
          .read(supabaseRepositoryProvider)
          .uploadProfileImage(user.id, pickedFile.path);
      ref.invalidate(myProfileProvider);
      ref.invalidate(profileProvider(user.id));
      if (mounted) {
        FlorenceToast.show(context, '프로필 사진이 변경되었습니다.');
      }
    } catch (e) {
      if (mounted) {
        FlorenceToast.show(context, '프로필 변경 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '로그인이 필요합니다';
    final booksAsync = ref.watch(userBooksProvider);
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(
          '마이 페이지',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.burgundy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile
            _buildProfileCard(context, profileAsync, email),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            // Statistics Section
            Text(
              '독서 통계',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 16),
            booksAsync.when(
              data: (books) {
                // ── 12개월 월별 통계 (1~12월 고정) ──
                final now = DateTime.now();
                final monthlyCounts = List.generate(12, (index) {
                  final month = index + 1; // 1월~12월
                  final count = books.where((b) {
                    if (b.status != 'read' || b.finishedAt == null)
                      return false;
                    return b.finishedAt!.year == now.year &&
                        b.finishedAt!.month == month;
                  }).length;
                  return {'month': month, 'count': count};
                });

                // ── 장르 통계 ──
                final genreCounts = <String, int>{};
                int totalRead = 0;
                for (var book in books) {
                  if (book.status == 'read') {
                    totalRead++;
                    final simpleCategory = _getSimpleCategory(
                      book.book.categoryName,
                    );
                    genreCounts[simpleCategory] =
                        (genreCounts[simpleCategory] ?? 0) + 1;
                  }
                }

                return Column(
                  children: [
                    // ──── 선호 장르 레이더 차트 ────
                    _buildRadarChartCard(context, genreCounts, totalRead),
                    const SizedBox(height: 16),
                    // ──── 월별 독서량 막대 차트 ────
                    _buildBarChartCard(context, monthlyCounts, now.month),
                  ],
                );
              },
              loading: () => const Center(child: FlorenceLoader()),
              error: (err, stack) => const SizedBox(),
            ),
            const SizedBox(height: 32),
            // Settings Button
            _buildMenuTile(
              context,
              icon: Icons.settings,
              title: '설정',
              onTap: () {
                context.push('/mypage/settings');
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Profile Card (unchanged)
  // ═══════════════════════════════════════════════════════
  Widget _buildProfileCard(
    BuildContext context,
    AsyncValue profileAsync,
    String email,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: profileAsync.when(
        data: (profile) {
          final nickname = profile?.nickname ?? '닉네임 미설정';
          final profileUrl = profile?.profileUrl;

          return Row(
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.burgundy,
                      backgroundImage:
                          profileUrl != null ? NetworkImage(profileUrl) : null,
                      child: profileUrl == null
                          ? const Icon(Icons.person,
                              size: 32, color: Colors.white)
                          : null,
                    ),
                    if (_isUploading)
                      const CircularProgressIndicator(color: Colors.white),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.charcoal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '닉네임 : ',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                  color: AppColors.grey,
                                ),
                          ),
                          TextSpan(
                            text: nickname,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.charcoal,
                                ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '오늘도 즐거운 독서 되세요!',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.greyLight),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Text('프로필을 불러올 수 없습니다.'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Radar Chart Card (선호 장르)
  // ═══════════════════════════════════════════════════════
  Widget _buildRadarChartCard(
    BuildContext context,
    Map<String, int> genreCounts,
    int totalRead,
  ) {
    // Compute normalized values for all 8 genres
    final maxCount = genreCounts.values.isNotEmpty
        ? genreCounts.values.reduce((a, b) => a > b ? a : b)
        : 0;
    final genreValues = _allGenres.map((g) {
      final count = genreCounts[g] ?? 0;
      return maxCount > 0 ? count / maxCount : 0.0;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.burgundy.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.burgundy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: _DuomoIconPainter(
                    color: AppColors.burgundy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '선호 장르',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                      fontSize: 16,
                    ),
              ),
              const Spacer(),
              if (totalRead > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.burgundy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '총 $totalRead권',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundy,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (totalRead == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.menu_book, size: 36, color: AppColors.greyLight),
                    SizedBox(height: 8),
                    Text(
                      '아직 읽은 책이 없습니다.',
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return SizedBox(
                  height: 280,
                  child: CustomPaint(
                    size: const Size(double.infinity, 280),
                    painter: _RadarChartPainter(
                      genres: _allGenres,
                      values: genreValues,
                      animationValue: _radarAnimation.value,
                      genreCounts: _allGenres
                          .map((g) => genreCounts[g] ?? 0)
                          .toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Bar Chart Card (월별 독서량)
  // ═══════════════════════════════════════════════════════
  Widget _buildBarChartCard(
    BuildContext context,
    List<Map<String, int>> monthlyCounts,
    int currentMonth,
  ) {
    final maxCount = monthlyCounts
        .map((e) => e['count'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.burgundy.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomPaint(
                    size: const Size(20, 20),
                    painter: _DuomoIconPainter(
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '월별 독서량',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _barAnimation,
            builder: (context, child) {
              // Book-inspired color palette (12 muted, warm tones)
              const barColors = [
                Color(0xFF8B4513), // saddle brown
                Color(0xFF5B7065), // sage green
                Color(0xFFA0522D), // sienna
                Color(0xFF4A6274), // steel blue
                Color(0xFF6B4226), // dark wood
                Color(0xFF7B6B5A), // warm taupe
                Color(0xFF8E735B), // camel
                Color(0xFF556B5E), // forest
                Color(0xFF9C6644), // copper
                Color(0xFF5D4E60), // dusty plum
                Color(0xFF7D6E5C), // khaki
                Color(0xFF7A5C47), // cocoa
              ];

              return SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthlyCounts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final count = data['count'] as int;
                    final month = data['month'] as int;
                    final isCurrentMonth = month == currentMonth;
                    final isOddMonth = month % 2 == 1;

                    final targetHeight = maxCount == 0
                        ? 4.0
                        : (count / maxCount) * 130.0;
                    final animatedHeight =
                        (targetHeight < 4 ? 4.0 : targetHeight) *
                            _barAnimation.value;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Count label (classic text, no bubble)
                            if (count > 0)
                              Opacity(
                                opacity: _barAnimation.value,
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isCurrentMonth
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isCurrentMonth
                                        ? AppColors.burgundy
                                        : AppColors.charcoal,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 14),
                            const SizedBox(height: 4),
                            // Bar (solid color, no gradient/glow)
                            Container(
                              width: double.infinity,
                              height: animatedHeight < 4 ? 4 : animatedHeight,
                              decoration: BoxDecoration(
                                color: count > 0
                                    ? barColors[index % barColors.length]
                                    : AppColors.greyLight.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Month label (only odd months)
                            Text(
                              isOddMonth ? '$month' : '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrentMonth
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isCurrentMonth
                                    ? AppColors.burgundy
                                    : AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.burgundy),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Radar Chart CustomPainter
// ═══════════════════════════════════════════════════════
class _RadarChartPainter extends CustomPainter {
  final List<String> genres;
  final List<double> values; // normalized 0.0 ~ 1.0
  final double animationValue;
  final List<int> genreCounts;

  _RadarChartPainter({
    required this.genres,
    required this.values,
    required this.animationValue,
    required this.genreCounts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 36;
    final sides = genres.length;
    final angleStep = (2 * pi) / sides;
    // Start from top (−π/2)
    const startAngle = -pi / 2;

    // ── Grid lines (concentric polygons) ──
    final gridPaint = Paint()
      ..color = AppColors.greyLight.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int level = 1; level <= 4; level++) {
      final levelRadius = radius * (level / 4);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = startAngle + angleStep * i;
        final point = Offset(
          center.dx + levelRadius * cos(angle),
          center.dy + levelRadius * sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Axis lines ──
    final axisPaint = Paint()
      ..color = AppColors.greyLight.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, end, axisPaint);
    }

    // ── Data polygon ──
    final dataPath = Path();
    final dataFillPaint = Paint()
      ..color = AppColors.burgundy.withOpacity(0.15 * animationValue)
      ..style = PaintingStyle.fill;
    final dataStrokePaint = Paint()
      ..color = AppColors.burgundy.withOpacity(0.8 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      // min 15% visible if has data
      final adjustedValue = values[i] > 0
          ? (0.15 + values[i] * 0.85) * animationValue
          : 0.0;
      final point = Offset(
        center.dx + radius * adjustedValue * cos(angle),
        center.dy + radius * adjustedValue * sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataFillPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // ── Data points (dots) ──
    final dotPaint = Paint()
      ..color = AppColors.burgundy
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final adjustedValue = values[i] > 0
          ? (0.15 + values[i] * 0.85) * animationValue
          : 0.0;
      if (adjustedValue > 0) {
        final point = Offset(
          center.dx + radius * adjustedValue * cos(angle),
          center.dy + radius * adjustedValue * sin(angle),
        );
        canvas.drawCircle(point, 4.5, dotBorderPaint);
        canvas.drawCircle(point, 3.0, dotPaint);
      }
    }

    // ── Determine top 3 genres ──
    final sortedIndices = List.generate(sides, (i) => i);
    sortedIndices.sort((a, b) => genreCounts[b].compareTo(genreCounts[a]));
    final top3Set = sortedIndices.take(3).where((i) => genreCounts[i] > 0).toSet();

    // ── Genre labels ──
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final isTop3 = top3Set.contains(i);
      final labelRadius = radius + 22; // Slightly closer but outside the last grid line
      final labelPos = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      final countText = genreCounts[i] > 0 ? '  ${genreCounts[i]}' : '';
      final textSpan = TextSpan(
        text: genres[i] + countText,
        style: TextStyle(
          fontSize: isTop3 ? 12.5 : 10.5,
          fontWeight: isTop3
              ? FontWeight.w900
              : (genreCounts[i] > 0 ? FontWeight.w700 : FontWeight.w400),
          color: isTop3
              ? AppColors.burgundy
              : (genreCounts[i] > 0
                  ? AppColors.charcoal
                  : AppColors.greyLight),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Better alignment based on position relative to center to avoid overlap
      double xOffset;
      double yOffset;

      final cosVal = cos(angle);
      final sinVal = sin(angle);

      // Horizontal alignment:
      // If noticeably on the right (cos > 0.1), anchor left (text grows right)
      // If noticeably on the left (cos < -0.1), anchor right (text grows left)
      // Otherwise (near top/bottom), center it.
      if (cosVal > 0.1) {
        xOffset = 0;
      } else if (cosVal < -0.1) {
        xOffset = -textPainter.width;
      } else {
        xOffset = -textPainter.width / 2;
      }

      // Vertical alignment:
      // If noticeably on the bottom (sin > 0.1), anchor top (text grows down)
      // If noticeably on the top (sin < -0.1), anchor bottom (text grows up)
      // Otherwise (near left/right), anchor middle.
      if (sinVal > 0.1) {
        yOffset = 0;
      } else if (sinVal < -0.1) {
        yOffset = -textPainter.height;
      } else {
        yOffset = -textPainter.height / 2;
      }

      final offset = Offset(labelPos.dx + xOffset, labelPos.dy + yOffset);
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.values != values;
  }
}

// ═══════════════════════════════════════════════════════
// Custom Icon: Florence Duomo Cathedral (Line Art)
// 피렌체 두오모 성당의 심플한 선형 아이콘
// ═══════════════════════════════════════════════════════
class _DuomoIconPainter extends CustomPainter {
  final Color color;
  _DuomoIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Main dome (large arc)
    final dome = Path()
      ..moveTo(w * 0.18, h * 0.55)
      ..quadraticBezierTo(w * 0.18, h * 0.18, w * 0.50, h * 0.15)
      ..quadraticBezierTo(w * 0.82, h * 0.18, w * 0.82, h * 0.55);
    canvas.drawPath(dome, paint);

    // Lantern (small tower on top of dome)
    canvas.drawLine(
      Offset(w * 0.50, h * 0.15),
      Offset(w * 0.50, h * 0.05),
      paint,
    );
    // Cross on top
    canvas.drawLine(
      Offset(w * 0.46, h * 0.07),
      Offset(w * 0.54, h * 0.07),
      paint,
    );

    // Drum (base of dome)
    canvas.drawLine(
      Offset(w * 0.14, h * 0.55),
      Offset(w * 0.86, h * 0.55),
      paint,
    );

    // Building body walls
    canvas.drawLine(
      Offset(w * 0.14, h * 0.55),
      Offset(w * 0.14, h * 0.88),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.86, h * 0.55),
      Offset(w * 0.86, h * 0.88),
      paint,
    );

    // Base line
    canvas.drawLine(
      Offset(w * 0.08, h * 0.88),
      Offset(w * 0.92, h * 0.88),
      paint,
    );

    // Left small window
    canvas.drawRect(
      Rect.fromLTWH(w * 0.24, h * 0.64, w * 0.12, h * 0.14),
      paint,
    );

    // Right small window
    canvas.drawRect(
      Rect.fromLTWH(w * 0.64, h * 0.64, w * 0.12, h * 0.14),
      paint,
    );

    // Center door (arch)
    final door = Path()
      ..moveTo(w * 0.40, h * 0.88)
      ..lineTo(w * 0.40, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.60, w * 0.60, h * 0.68)
      ..lineTo(w * 0.60, h * 0.88);
    canvas.drawPath(door, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

