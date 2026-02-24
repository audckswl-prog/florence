import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
// import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../library/providers/library_providers.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '로그인이 필요합니다';
    final booksAsync = ref.watch(userBooksProvider);

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
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.burgundy,
                    child: Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '오늘도 즐거운 독서 되세요!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  final targetMonth = DateTime(now.year, now.month - (5 - index), 1);
                  final count = books.where((b) {
                    if (b.status != 'read' || b.finishedAt == null) return false;
                    return b.finishedAt!.year == targetMonth.year && b.finishedAt!.month == targetMonth.month;
                  }).length;
                  return {'month': targetMonth.month, 'count': count};
                });

                // 2. Calculate Genre Stats
                final genreCounts = <String, int>{};
                int totalRead = 0;
                for (var book in books) {
                  if (book.status == 'read') {
                    totalRead++;
                    final category = book.book.categoryName.split('>').lastOrNull?.trim() ?? '기타';
                     // Simplify category name
                    final simpleCategory = category.split(' ').first;
                    genreCounts[simpleCategory] = (genreCounts[simpleCategory] ?? 0) + 1;
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
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
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
                          Text('월별 독서량', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: monthlyCounts.map((data) {
                              final count = data['count'] as int;
                              final month = data['month'] as int;
                              final maxCount = monthlyCounts.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b);
                              final height = maxCount == 0 ? 0.0 : (count / maxCount) * 100.0;
                              
                              return Column(
                                children: [
                                  Text('$count', style: const TextStyle(fontSize: 10, color: AppColors.burgundy, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 12,
                                    height: height == 0 ? 4 : height, // Min height 4
                                    decoration: BoxDecoration(
                                      color: AppColors.burgundy.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('$month월', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
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
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
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
                          Text('선호 장르', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 16),
                          if (sortedGenres.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('아직 읽은 책이 없습니다.', style: TextStyle(color: AppColors.grey))),
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
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                                              color: AppColors.greyLight.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: percentage,
                                            child: Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppColors.burgundy,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
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

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
