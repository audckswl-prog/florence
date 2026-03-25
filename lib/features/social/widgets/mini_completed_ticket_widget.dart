import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../social/providers/social_providers.dart';

class MiniCompletedTicketWidget extends StatelessWidget {
  final ProjectWithMembers projectWithMembers;

  const MiniCompletedTicketWidget({
    Key? key,
    required this.projectWithMembers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final project = projectWithMembers.project;
    final coverUrl = projectWithMembers.firstBookCover;
    
    // 프로젝트 완료일 또는 생성일을 표시
    final dateStr = project.endDate != null 
        ? DateFormat('yyyy.MM.dd').format(project.endDate!)
        : DateFormat('yyyy.MM.dd').format(project.createdAt);

    return GestureDetector(
      onTap: () {
        context.push('/home/social/detail/${project.id}');
      },
      child: Container(
        width: 180, // 세로형 비율 (너비)
        height: 280, // 세로형 비율 (높이)
        decoration: BoxDecoration(
          color: const Color(0xFFF9F6F0), // 프리미엄 웜 크림 베이지
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // 부드러운 그림자
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // 티켓 형상을 띠도록 ClipPath 적용
        child: ClipPath(
          clipper: _MiniTicketClipper(notchRadius: 8, notchY: 76),
          child: Container(
            color: const Color(0xFFF9F6F0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header: Firenze Logo & Date ---
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Firenze',
                            style: TextStyle(
                              fontFamily: 'PinyonScript',
                              fontSize: 24,
                              color: AppColors.burgundy,
                              height: 1.0,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'DATE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.greyLight,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // --- Perforation (점선) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final dashCount = (width / 6).floor();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              dashCount,
                              (_) => Container(
                                width: 3,
                                height: 1.5,
                                color: AppColors.greyLight.withOpacity(0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // --- Book Cover Area ---
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            // 살짝 들어간 듯한 느낌을 주는 블록 (프리미엄티켓테마)
                            color: const Color(0xFFF0EAE1), 
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: coverUrl != null && coverUrl.isNotEmpty
                                ? Image.network(
                                    coverUrl.replaceAll('coversum', 'cover200'),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppColors.ivory,
                                    child: const Center(
                                      child: Icon(Icons.book, color: AppColors.greyLight),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    // --- Footer: Project Name & Status ---
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              // 멤버가 2명 이상이면 '누구누구 님과의 독서' 형태로 표시
                              final myId = Supabase.instance.client.auth.currentUser?.id;
                              final others = projectWithMembers.members.where((m) => m.userId != myId).toList();
                              final displayName = others.isNotEmpty && others.first.nickname != null
                                  ? '${others.first.nickname}님과 독서'
                                  : project.name;
                                  
                              return Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.charcoal,
                                  fontFamily: 'Pretendard',
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'COMPLETED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.burgundy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // --- 'READ' 도장 효과 ---
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.burgundy.withOpacity(0.85), 
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'READ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.burgundy.withOpacity(0.85),
                          letterSpacing: 2.0,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
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

/// 티켓의 양옆에 반원 모양의 펀칭(홈)을 파는 Clipper
class _MiniTicketClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchY;

  _MiniTicketClipper({required this.notchRadius, required this.notchY});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = notchRadius;
    final path = Path();
    
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    
    // Right Edge with notch
    path.lineTo(w, notchY - r);
    path.arcToPoint(
      Offset(w, notchY + r),
      radius: Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(w, h);
    
    // Bottom Edge
    path.lineTo(0, h);
    
    // Left Edge with notch
    path.lineTo(0, notchY + r);
    path.arcToPoint(
      Offset(0, notchY - r),
      radius: Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(0, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_MiniTicketClipper oldClipper) => 
      oldClipper.notchRadius != notchRadius || oldClipper.notchY != notchY;
}
