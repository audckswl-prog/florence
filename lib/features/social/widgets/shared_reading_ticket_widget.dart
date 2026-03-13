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
    // 위젯의 내용물을 먼저 구성하고, ClipPath로 펀칭 구멍을 뚫음
    final content = Container(
      color: const Color(0xFFF5F0EB),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 위쪽 연장 여백 (종이가 위로 이어지는 느낌)
          const SizedBox(height: 30),
          _buildHeader(),
          _buildBarcode(),
          ...members.asMap().entries.expand((entry) {
            final index = entry.key;
            final member = entry.value;
            final profile = memberProfiles[member.userId];
            final isFirst = index % 2 == 0;
            return [
              _buildPerforationLine(),
              _buildMemberSection(member, profile, isFirst, index + 1),
            ];
          }),
          const SizedBox(height: 16),
          // 아래쪽 연장 여백 (종이가 아래로 이어지는 느낌)
          const SizedBox(height: 30),
        ],
      ),
    );

    // ClipPath로 펀칭 구멍을 실제로 뚫어서 뒤 배경이 보이게 함
    return ClipPath(
      clipper: _TicketPunchClipper(
        punchRadius: 12.0,
        memberCount: members.length,
      ),
      child: content,
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
    final bookCover = member.selectedBookCover;
    final drawingUrl = member.drawingUrl;
    final quote = member.quote ?? '';
    final totalPages = member.totalPages;

    final bookWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: bookCover != null && bookCover.isNotEmpty
          ? Image.network(
              bookCover,
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
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: drawingUrl != null && drawingUrl.isNotEmpty
          ? Image.network(
              drawingUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.brush, color: Colors.orange, size: 28)),
            )
          : const Center(child: Icon(Icons.brush, color: Colors.orange, size: 28)),
    );

    final nicknameBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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

    Widget cardArea;
    if (bookOnLeft) {
      cardArea = SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: bookWidget),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [nicknameBadge, const SizedBox(height: 6), Expanded(child: drawingWidget)],
              ),
            ),
          ],
        ),
      );
    } else {
      cardArea = SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [nicknameBadge, const SizedBox(height: 6), Expanded(child: drawingWidget)],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 5, child: bookWidget),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          cardArea,
          const SizedBox(height: 6),
          Align(
            alignment: bookOnLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Text(
              'P.$totalPages',
              style: TextStyle(fontSize: 10, color: AppColors.charcoal.withOpacity(0.6), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 50,
            child: quote.isNotEmpty
                ? Text(
                    '"$quote"',
                    style: const TextStyle(fontSize: 11, height: 1.6, color: AppColors.charcoal, fontWeight: FontWeight.w500),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
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
class _TicketPunchClipper extends CustomClipper<Path> {
  final double punchRadius;
  final int memberCount;

  _TicketPunchClipper({
    required this.punchRadius,
    required this.memberCount,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (memberCount <= 0) return path;

    // 종이 구조 높이 계산
    // 위 여백(30) + 헤더(~50) + 바코드(~48) = ~128
    // 각 멤버 앞: 절취선(~6) + 멤버섹션(~228) = ~234
    // 아래 여백(46)
    final topOffset = 30.0 + 50.0 + 48.0;
    const sectionHeight = 234.0;

    for (int i = 0; i < memberCount; i++) {
      final y = topOffset + (sectionHeight * i);

      // 왼쪽 반원 구멍
      path.addOval(Rect.fromCircle(
        center: Offset(0, y),
        radius: punchRadius,
      ));
      // 오른쪽 반원 구멍
      path.addOval(Rect.fromCircle(
        center: Offset(size.width, y),
        radius: punchRadius,
      ));
    }

    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(_TicketPunchClipper oldClipper) =>
      oldClipper.memberCount != memberCount || oldClipper.punchRadius != punchRadius;
}
