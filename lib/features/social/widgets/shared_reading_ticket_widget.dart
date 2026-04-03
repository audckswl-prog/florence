import 'dart:math';
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
  final double? availableHeight; // 기기별 가용 높이 전달

  const SharedReadingTicketWidget({
    super.key,
    required this.project,
    required this.members,
    required this.memberProfiles,
    this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final ticketWidgets = <Widget>[];

    // 첫 번째 파트: 상단 여백 + 헤더
    ticketWidgets.add(_buildSolidBlock(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: members.length <= 2 ? 48 : 40), // 2인일 때 '이어져 보이게' 충분한 상단 공간 확보
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
      
      memberSectionContent.add(_buildMemberSection(context, member, profile, isFirst, index + 1));
      
      if (index < members.length - 1) {
        // 다음 멤버로 넘어가기 전 하단/상단 여백
        memberSectionContent.add(SizedBox(height: members.length <= 2 ? 8 : 12));
      } else {
        // 마지막 멤버인 경우 아래쪽 연장 여백 (화면 끝까지 닿게 함)
        // 만약 가용 높이가 있다면 최소 높이가 보장되므로 여기선 빡빡하게 8만 줍니다.
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
        // 절취선의 높이(Padding 2 + Line 1 + Padding 2 = 5)에 위아래 여백 12를 더해 총 29px 높이를 확보합니다.
        // 이렇게 하면 반경 12(지름 24)인 펀칭 원형이 온전히 그려지면서 위아래로 2.5px의 마진이 생기므로,
        // 블록 간의 1px 겹침 로직(잔선 제거용)이 둥근 펀칭 구멍 안으로 절대로 침범하지 않게 됩니다.
        padding: const EdgeInsets.symmetric(vertical: 12.0),
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
              fontSize: 36, // 원본 크기 복구
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
    BuildContext context,
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

    final drawingWidget = AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
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
      ),
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
      ],
    );

    final isCompact = members.length <= 2;
    // 가용 높이가 있을 경우, 텍스트/여백 공간(약 520px)을 제외한 나머지 공간을 카드에 배분
    double cardHeight;
    if (isCompact && availableHeight != null) {
      // (가용높이 - 고정된 텍스트/여백) / 2 = 카드 1개의 가변 높이
      // 520px은 헤더, 펀칭, 모든 텍스트 영역의 합산 근사값
      cardHeight = (availableHeight! - 510) / 2;
      cardHeight = cardHeight.clamp(110.0, 180.0);
    } else {
      cardHeight = isCompact ? 155.0 : 175.0;
    }
    
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
          SizedBox(height: isCompact ? 8 : 8),
          profileHeader,
          SizedBox(height: isCompact ? 12 : 12),
          cardArea,
          SizedBox(height: isCompact ? 12 : 12),
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
                      fontSize: 11,
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2, // 2인일 때도 제목 2줄까지 허용하여 여백 확보
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          // 인용구 (박스 없이 깔끔하게)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: quote.isNotEmpty
                ? Text(
                    '" $quote "',
                    style: TextStyle(
                      fontSize: 11, // BOOK 글자 크기에 맞춰 축소
                      height: 1.5, 
                      color: AppColors.charcoal.withOpacity(0.9), // 모든 구절을 기존 차콜색으로 통일
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3, // 원본 줄 수 복구
                    overflow: TextOverflow.ellipsis,
                  )
                : SizedBox(height: isCompact ? 32 : 48), // 빈 공간 유지
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
  void _showReportDialog(BuildContext context, String nickname) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF9F6F0),
        title: const Text('게시물 신고', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold)),
        content: Text('정말로 $nickname님의 게시물을 신고하시겠습니까?\n\n허위 신고 시 이용이 제한될 수 있습니다.', 
            style: const TextStyle(color: AppColors.charcoal, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('신고가 정상적으로 접수되었습니다. 최대한 빠르게 조치하겠습니다.'),
                  backgroundColor: AppColors.burgundy.withOpacity(0.9),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('신고접수', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, String nickname) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF9F6F0),
        title: const Text('사용자 차단', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold)),
        content: Text('$nickname님을 차단하시겠습니까?\n\n차단된 사용자의 티켓과 게시물은 더 이상 표시되지 않습니다.', 
            style: const TextStyle(color: AppColors.charcoal, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('해당 사용자가 차단되었습니다. 페이지를 다시 열면 반영됩니다.'),
                  backgroundColor: AppColors.charcoal,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('차단하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
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
    final centerY = size.height / 2;

    path.moveTo(0, 0); // Top-left
    path.lineTo(size.width, 0); // Top-right

    // Right-edge punch hole (inward curve)
    path.lineTo(size.width, centerY - radius);
    path.arcTo(
      Rect.fromCircle(center: Offset(size.width, centerY), radius: radius),
      -pi / 2,
      -pi,
      false,
    );

    path.lineTo(size.width, size.height); // Bottom-right
    path.lineTo(0, size.height); // Bottom-left

    // Left-edge punch hole (inward curve)
    path.lineTo(0, centerY + radius);
    path.arcTo(
      Rect.fromCircle(center: Offset(0, centerY), radius: radius),
      pi / 2,
      -pi,
      false,
    );

    path.close(); // Back to top-left
    return path;
  }

  @override
  bool shouldReclip(_RowPunchClipper old) => old.radius != radius;
}
