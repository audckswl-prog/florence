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

  // Fixed 8 genre categories (same as existing logic)
  static const List<String> _allGenres = [
    '소설',
    '경제·경영',
    '자기계발',
    '에세이·시',
    '인문·사회',
    'IT·과학',
    '인물·전기',
    '기타 도서',
  ];

  String _getSimpleCategory(String rawCategory) {
    if (rawCategory.contains('소설')) return '소설';
    if (rawCategory.contains('경제') || rawCategory.contains('경영'))
      return '경제·경영';
    if (rawCategory.contains('자기계발')) return '자기계발';
    if (rawCategory.contains('에세이') || rawCategory.contains('시'))
      return '에세이·시';
    if (rawCategory.contains('인문') ||
        rawCategory.contains('사회') ||
        rawCategory.contains('역사'))
      return '인문·사회';
    if (rawCategory.contains('IT') ||
        rawCategory.contains('컴퓨터') ||
        rawCategory.contains('과학'))
      return 'IT·과학';
    if (rawCategory.contains('인물') ||
        rawCategory.contains('전기') ||
        rawCategory.contains('자서전'))
      return '인물·전기';
    return '기타 도서';
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
                // ── 12개월 월별 통계 ──
                final now = DateTime.now();
                final monthlyCounts = List.generate(12, (index) {
                  final targetMonth = DateTime(
                    now.year,
                    now.month - (11 - index),
                    1,
                  );
                  final count = books.where((b) {
                    if (b.status != 'read' || b.finishedAt == null)
                      return false;
                    return b.finishedAt!.year == targetMonth.year &&
                        b.finishedAt!.month == targetMonth.month;
                  }).length;
                  return {'month': targetMonth.month, 'count': count};
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
                child: const Icon(Icons.auto_stories,
                    color: AppColors.burgundy, size: 20),
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
                  child: const Icon(Icons.bar_chart_rounded,
                      color: AppColors.charcoal, size: 20),
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
              return SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthlyCounts.asMap().entries.map((entry) {
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
                            // Count label (only for non-zero)
                            if (count > 0)
                              Opacity(
                                opacity: _barAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCurrentMonth
                                        ? AppColors.burgundy
                                        : AppColors.charcoal,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 18),
                            const SizedBox(height: 4),
                            // Bar
                            Container(
                              width: double.infinity,
                              height: animatedHeight < 4 ? 4 : animatedHeight,
                              decoration: BoxDecoration(
                                gradient: count > 0
                                    ? LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: isCurrentMonth
                                            ? [
                                                AppColors.burgundy,
                                                const Color(0xFFB83A3E),
                                              ]
                                            : [
                                                AppColors.charcoal
                                                    .withOpacity(0.7),
                                                AppColors.charcoal,
                                              ],
                                      )
                                    : null,
                                color: count == 0
                                    ? AppColors.greyLight.withOpacity(0.2)
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: count > 0 && isCurrentMonth
                                    ? [
                                        BoxShadow(
                                          color: AppColors.burgundy
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
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

    // ── Genre labels ──
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final labelRadius = radius + 24;
      final labelPos = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      final countText = genreCounts[i] > 0 ? '  ${genreCounts[i]}' : '';
      final textSpan = TextSpan(
        text: genres[i] + countText,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight:
              genreCounts[i] > 0 ? FontWeight.w700 : FontWeight.w400,
          color: genreCounts[i] > 0
              ? AppColors.charcoal
              : AppColors.greyLight,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Center the label around the label position
      final offset = Offset(
        labelPos.dx - textPainter.width / 2,
        labelPos.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.values != values;
  }
}
