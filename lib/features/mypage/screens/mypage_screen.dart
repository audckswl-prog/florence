import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../core/utils/florence_toast.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../../library/providers/library_providers.dart';
import '../../library/providers/book_providers.dart';
import '../../social/providers/social_providers.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool _isUploading = false;

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
      // Invalidate the profile provider so it re-fetches the new image
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000), // Very subtle shadow
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
                              backgroundImage: profileUrl != null
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 32,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            if (_isUploading)
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.charcoal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 12,
                                  color: Colors.white,
                                ),
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.grey,
                                    fontSize: 13,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '오늘도 즐거운 독서 되세요!',
                              style: Theme.of(context).textTheme.bodySmall
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
            ),
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
                // 1. Calculate Monthly Stats (Last 6 months)
                final now = DateTime.now();
                final monthlyCounts = List.generate(6, (index) {
                  final targetMonth = DateTime(
                    now.year,
                    now.month - (5 - index),
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

                // 2. Calculate Genre Stats
                String getSimpleCategory(String rawCategory) {
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

                final genreCounts = <String, int>{};
                int totalRead = 0;
                for (var book in books) {
                  if (book.status == 'read') {
                    totalRead++;
                    final simpleCategory = getSimpleCategory(
                      book.book.categoryName,
                    );
                    genreCounts[simpleCategory] =
                        (genreCounts[simpleCategory] ?? 0) + 1;
                  }
                }
                final sortedGenres = genreCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  children: [
                    // Monthly Bar Chart
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000), // Very subtle shadow
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '월별 독서량',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: monthlyCounts.map((data) {
                              final count = data['count'] as int;
                              final month = data['month'] as int;
                              final maxCount = monthlyCounts
                                  .map((e) => e['count'] as int)
                                  .reduce((a, b) => a > b ? a : b);
                              final height = maxCount == 0
                                  ? 0.0
                                  : (count / maxCount) * 100.0;

                              return Column(
                                children: [
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.burgundy,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 12,
                                    height: height == 0
                                        ? 4
                                        : height, // Min height 4
                                    decoration: BoxDecoration(
                                      color: AppColors.burgundy.withOpacity(
                                        0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$month월',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Genre Distribution
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000), // Very subtle shadow
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '선호 장르',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          if (sortedGenres.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  '아직 읽은 책이 없습니다.',
                                  style: TextStyle(color: AppColors.grey),
                                ),
                              ),
                            )
                          else
                            ...sortedGenres.take(5).map((entry) {
                              final percentage = (entry.value / totalRead);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColors.greyLight
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: percentage,
                                            child: Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppColors.burgundy,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
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
              color: Color(0x0D000000), // Very subtle shadow
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
