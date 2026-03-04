import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
// import '../../../../core/widgets/neumorphic_container.dart';

class SocialStoriesWidget extends StatelessWidget {
  const SocialStoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for stories
    final stories = [
      {'name': '내 스토리', 'isMe': true, 'hasUpdate': false},
      {'name': '김철수', 'isMe': false, 'hasUpdate': true},
      {'name': '이영희', 'isMe': false, 'hasUpdate': true},
      {'name': '박민수', 'isMe': false, 'hasUpdate': false},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final story = stories[index];
          final isMe = story['isMe'] as bool;
          final hasUpdate = story['hasUpdate'] as bool;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: hasUpdate
                      ? Border.all(color: AppColors.burgundy, width: 2)
                      : Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ), // Subtle border for non-updates
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: isMe
                      ? const Icon(Icons.add, color: AppColors.burgundy)
                      : const Icon(Icons.person, color: AppColors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                story['name'] as String,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.charcoal,
                  fontSize: 11,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
