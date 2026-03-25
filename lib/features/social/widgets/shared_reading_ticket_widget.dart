import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          const SizedBox(height: 30),
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
        // 이전 멤버 섹션과 이어지는 맨 윗 공간
        memberSectionContent.add(const SizedBox(height: 8));
      }
      
      memberSectionContent.add(_buildMemberSection(member, profile, isFirst, index + 1));
      
      if (index < members.length - 1) {
        // 다음 절취선 전의 아랫 공간
        memberSectionContent.add(const SizedBox(height: 12));
      } else {
        // 마지막 멤버인 경우 아래쪽 연장 여백 추가
        memberSectionContent.add(const SizedBox(height: 16));
        memberSectionContent.add(const SizedBox(height: 30));
      }
      
      ticketWidgets.add(_buildSolidBlock(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: memberSectionContent,
        )
      ));

      if (index < members.length - 1) {
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
        color: Color(0xFFF5F0EB),
      ),
      child: child,
    );
  }

  Widget _buildPunchedBlock(Widget child) {
    return ClipPath(
      clipper: const _RowPunchClipper(radius: 12.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0EB),
        ),
        // 높이를 강제하지 않고 child(절취선)의 높이에 맞추되 여유 공간을 둡니다.
        // 절취선의 높이(Padding 2 + Line 1 + Padding 2 = 5)에 위아래 여백을 더하여 펀칭 원형(지름 24)이 충분히 뚫리게 합니다.
        padding: const EdgeInsets.symmetric(vertical: 9.5), // (24 - 5) / 2
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Text(
        'Firenze',
        style: GoogleFonts.greatVibes(
          fontSize: 36,
          color: AppColors.burgundy,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildBarcode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: CustomPaint(
        size: const Size(double.infinity, 36),
        painter: _BarcodePainter(),
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
        color: Colors.white,
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

    final nicknameBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.ivory,
            child: Icon(Icons.person, size: 16, color: AppColors.burgundy.withOpacity(0.7)),
          ),
          const SizedBox(height: 3),
          Text(
            '닉네임 $memberIndex',
            style: TextStyle(fontSize: 8, color: AppColors.charcoal.withOpacity(0.5)),
          ),
          Text(
            nickname,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.charcoal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    // 교차 카드 레이아웃: 책표지(비율 고정) + 그림(공간 차지)
    Widget cardArea;
    if (bookOnLeft) {
      // 멤버 1: 왼쪽 책표지, 오른쪽 그림 (닉네임 배지가 우상단에 겹침)
      cardArea = SizedBox(
        height: 180,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(aspectRatio: 1 / 1.45, child: bookWidget),
                const SizedBox(width: 8),
                Expanded(child: drawingWidget),
              ],
            ),
            // 닉네임 배지: 우상단에 겹침
            Positioned(
              top: -8,
              right: 0,
              child: nicknameBadge,
            ),
          ],
        ),
      );
    } else {
      // 멤버 2: 왼쪽 그림, 오른쪽 책표지 (닉네임 배지가 좌상단에 겹침)
      cardArea = SizedBox(
        height: 180,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: drawingWidget),
                const SizedBox(width: 8),
                AspectRatio(aspectRatio: 1 / 1.45, child: bookWidget),
              ],
            ),
            // 닉네임 배지: 좌상단에 겹침
            Positioned(
              top: -8,
              left: 0,
              child: nicknameBadge,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          cardArea,
          const SizedBox(height: 6),
          // 페이지 수 (반응형 텍스트)
          Text(
            'P.$totalPages',
            style: TextStyle(fontSize: 10, color: AppColors.charcoal.withOpacity(0.6), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          // 인용구: 전체 너비 응답성 유지, 내용은 유동적
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDE8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: quote.isNotEmpty
                ? Text(
                    '"$quote"',
                    style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.charcoal, fontWeight: FontWeight.w500),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox(height: 56), // 빈 공간 유지
          ),
        ],
      ),
    );
  }
}

/// 실제 바코드처럼 그리는 CustomPainter
class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.fill;

    // 바코드 패턴: 바 두께와 간격 (1=얇은, 2=중간, 3=두꺼운)
    // 실제 Code 128 느낌으로 바-간격-바-간격 반복
    final List<double> bars = [];
    // 시드 패턴으로 리얼한 바코드 생성
    final widths = [1.0, 1.5, 2.0, 2.5, 3.0];
    final gaps = [0.8, 1.0, 1.5, 2.0];
    
    double x = 0;
    int i = 0;
    while (x < size.width) {
      // 바 그리기
      final barW = widths[i % widths.length];
      if (x + barW > size.width) break;
      canvas.drawRect(Rect.fromLTWH(x, 0, barW, size.height), paint);
      x += barW;
      
      // 간격
      final gapW = gaps[(i * 3 + 1) % gaps.length];
      x += gapW;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
