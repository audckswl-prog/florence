import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';

/// Shared Reading Ticket Widget
/// Looks like a continuous receipt paper with:
/// - No rounded corners (paper extends top/bottom)  
/// - Real transparent punch holes cut via ClipPath
/// - Dashed perforation lines between punch holes
/// - Realistic barcode with tightly packed bars
class SharedReadingTicketWidget extends StatelessWidget {
  final Project project;
  final List<ProjectMember> members;
  final Map<String, Profile> memberProfiles;

  const SharedReadingTicketWidget({
    super.key,
    required this.project,
    required this.members,
    required this.memberProfiles,
  });

  @override
  Widget build(BuildContext context) {
    final ticketWidgets = <Widget>[];

    // 첫 번째 파트: 상단 여백 + 헤더
    ticketWidgets.add(_buildSolidBlock(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: members.length <= 2 ? 32 : 40), // 2인일 때 '끊긴 느낌' 없도록 여백 살짝 확보
          _buildHeader(),
        ],
      )
    ));
    
    // 첫 번째 절취선 + 펀칭
    ticketWidgets.add(_buildPunchedBlock(_buildPerforationLine()));

    // 멤버 섹션 (각각의 멤버 콘텐츠를 하나의 큰 Solid 블록으로 묶음)
    for (int index = 0; index < members.length; index++) {
      final member = members[index];
      final profile = memberProfiles[member.userId];
      final isFirst = index % 2 == 0;
      
      final memberSectionContent = <Widget>[];
      
      if (index > 0) {
        // 이전 멤버 섹션과 이어지는 맨 윗 공간 (간격 더 줄임)
        memberSectionContent.add(SizedBox(height: members.length <= 2 ? 2 : 8));
      }
      
      memberSectionContent.add(_buildMemberSection(member, profile, isFirst, index + 1));
      
      if (index < members.length - 1) {
        // 다음 멤버로 넘어가기 전 하단/상단 여백
        memberSectionContent.add(SizedBox(height: members.length <= 2 ? 6 : 12));
      } else {
        // 마지막 멤버인 경우 아래쪽 연장 여백 (기존 16에서 8로 더 축소하여 하단 탭 바 회피)
        memberSectionContent.add(SizedBox(height: members.length <= 2 ? 8 : 48));
      }
      
      ticketWidgets.add(_buildSolidBlock(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: memberSectionContent,
        )
      ));

      if (index < members.length - 1) {
        // 푸터 대신 다음 멤버 사이에만 절취선
        ticketWidgets.add(_buildPunchedBlock(_buildPerforationLine()));
      }
    }

    final layeredWidgets = <Widget>[];
    for (int i = 0; i < ticketWidgets.length; i++) {
      layeredWidgets.add(
        Transform.translate(
          offset: Offset(0, -1.0 * i),
          child: ticketWidgets[i],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: layeredWidgets,
    );
  }

  Widget _buildSolidBlock(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6F0),
      ),
      child: child,
    );
  }

  Widget _buildPunchedBlock(Widget child) {
    return ClipPath(
      clipper: const _RowPunchClipper(radius: 12.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9F6F0),
        ),
        // 높이를 강제하지 않고 child(절취선)의 높이에 맞추되 여유 공간을 둡니다.
        // 절취선의 높이(Padding 2 + Line 1 + Padding 2 = 5)에 위아래 여백을 더하여 펀칭 원형(지름 24)이 충분히 뚫리게 합니다.
        padding: const EdgeInsets.symmetric(vertical: 8.0), // 8.5에서 8.0으로 극미량 추가 축소
        child: child,
      ),
    );
  }

  /// 절취선: 점선만 (펀칭 구멍은 ClipPath가 처리)
  Widget _buildPerforationLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (_, constraints) {
          const dashW = 5.0, gap = 3.0;
          final count = (constraints.maxWidth / (dashW + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              count,
              (_) => Container(
                width: dashW,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: gap / 2),
                color: AppColors.grey.withOpacity(0.4),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final String dateString = DateFormat('yyyy.MM.dd').format(project.endDate ?? project.createdAt);
    final isCompact = members.length <= 2;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, isCompact ? 12 : 16, 24, isCompact ? 4 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Firenze',
            style: GoogleFonts.greatVibes(
              fontSize: isCompact ? 30 : 36, // 폰트 크기 살짝 축소
              color: AppColors.burgundy,
              fontWeight: FontWeight.w400,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DATE',
                style: TextStyle(
                  fontSize: 7,
                  letterSpacing: 2.0,
                  color: AppColors.burgundy.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateString,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSection(
    ProjectMember member,
    Profile? profile,
    bool bookOnLeft,
    int memberIndex,
  ) {
    final nickname = profile?.nickname ?? 'Member ${member.userId.substring(0, 4)}';
    
    // 알라딘 API 썸네일 URL을 고화질(cover500)로 자동 변환
    String? highResCover = member.selectedBookCover;
    if (highResCover != null && highResCover.contains('aladin.co.kr')) {
      highResCover = highResCover.replaceAll(
        RegExp(r'coversum|cover150|cover200'),
        'cover500',
      );
    }
    
    final drawingUrl = member.drawingUrl;
    final quote = member.quote ?? '';
    final totalPages = member.totalPages;

    final bookWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: highResCover != null && highResCover.isNotEmpty
          ? Image.network(
              highResCover,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.ivory,
                child: const Center(child: Icon(Icons.menu_book, color: AppColors.greyLight, size: 32)),
              ),
            )
          : Container(
              color: AppColors.ivory,
              child: const Center(child: Icon(Icons.menu_book, color: AppColors.greyLight, size: 32)),
            ),
    );

    final drawingWidget = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE1),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: drawingUrl != null && drawingUrl.isNotEmpty
          ? Image.network(
              drawingUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.brush, color: AppColors.greyLight, size: 28)),
            )
          : const Center(child: Icon(Icons.brush, color: AppColors.greyLight, size: 28)),
    );

    final profileHeader = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.burgundy.withOpacity(0.3), width: 1.0),
          ),
          child: ClipOval(
            child: profile?.profileUrl != null
                ? Image.network(profile!.profileUrl!, fit: BoxFit.cover)
                : Icon(Icons.person, size: 16, color: AppColors.burgundy.withOpacity(0.7)),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'READER.0$memberIndex',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: AppColors.burgundy.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              nickname,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );

    final isCompact = members.length <= 2;
    final cardHeight = isCompact ? 115.0 : 175.0; // 2인일 때 카드 높이 대폭 축소
    
    // 교차 카드 레이아웃: 책표지(비율 고정) + 그림(공간 차지)
    Widget cardArea;
    if (bookOnLeft) {
      // 멤버 1: 왼쪽 책표지, 오른쪽 그림
      cardArea = SizedBox(
        height: cardHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 1 / 1.45, child: bookWidget),
            const SizedBox(width: 8),
            Expanded(child: drawingWidget),
          ],
        ),
      );
    } else {
      // 멤버 2: 왼쪽 그림, 오른쪽 책표지
      cardArea = SizedBox(
        height: cardHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: drawingWidget),
            const SizedBox(width: 8),
            AspectRatio(aspectRatio: 1 / 1.45, child: bookWidget),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20, 
        vertical: isCompact ? 0 : 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isCompact ? 2 : 8),
          profileHeader,
          SizedBox(height: isCompact ? 4 : 12),
          cardArea,
          SizedBox(height: isCompact ? 4 : 12),
          // Book Title Row
          Container(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8, horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.burgundy.withOpacity(0.1), width: 1.0),
                bottom: BorderSide(color: AppColors.burgundy.withOpacity(0.1), width: 1.0),
              )
            ),
            child: Row(
              children: [
                Text(
                  'BOOK',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppColors.burgundy.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.selectedBookTitle ?? '제목 없음',
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1, // 2인일 때 제목 한 줄로 제한
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 4 : 16),
          // 인용구 (박스 없이 깔끔하게)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: quote.isNotEmpty
                ? Text(
                    '" $quote "',
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 13, 
                      height: 1.4, 
                      color: AppColors.charcoal.withOpacity(0.9), 
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: isCompact ? 2 : 3, // 2인일 때 인용구 줄 수 축소
                    overflow: TextOverflow.ellipsis,
                  )
                : SizedBox(height: isCompact ? 10 : 48), // 빈 공간 유지
          ),
          SizedBox(height: isCompact ? 2 : 8),
          // 페이지 수 
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— P.$totalPages',
              style: TextStyle(
                fontSize: 10, 
                color: AppColors.burgundy.withOpacity(0.8), 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 0 : 4),
        ],
      ),
    );
  }
}

/// ClipPath로 양쪽에 실제 반원 구멍을 뚫어내는 Clipper
/// 뒤의 배경(블러 이미지)이 보이게 됨
class _RowPunchClipper extends CustomClipper<Path> {
  final double radius;

  const _RowPunchClipper({required this.radius});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final centerY = size.height / 2;

    path.addOval(Rect.fromCircle(
      center: Offset(0, centerY),
      radius: radius,
    ));
    path.addOval(Rect.fromCircle(
      center: Offset(size.width, centerY),
      radius: radius,
    ));

    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(_RowPunchClipper old) => old.radius != radius;
}
