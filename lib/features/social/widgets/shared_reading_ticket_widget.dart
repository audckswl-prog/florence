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
      
      // 섹션 하단 공간
      memberSectionContent.add(const SizedBox(height: 16));
      
      ticketWidgets.add(_buildSolidBlock(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: memberSectionContent,
        )
      ));

      // 푸터 전 절취선 추가
      ticketWidgets.add(_buildPunchedBlock(_buildPerforationLine()));
    }

    // 바코드 & 푸터 추가
    ticketWidgets.add(_buildFooter());

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

  Widget _buildFooter() {
    return _buildSolidBlock(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // 시리얼 넘버 & 푸터 텍스트
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  project.id.split('-').first.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.0,
                    color: AppColors.charcoal.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Grazie per la lettura',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.burgundy.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 바코드
            SizedBox(
              height: 40,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarcodePainter(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String dateString = DateFormat('yyyy.MM.dd').format(project.endDate ?? project.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Firenze',
            style: GoogleFonts.greatVibes(
              fontSize: 36,
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

    // 교차 카드 레이아웃: 책표지(비율 고정) + 그림(공간 차지)
    Widget cardArea;
    if (bookOnLeft) {
      // 멤버 1: 왼쪽 책표지, 오른쪽 그림
      cardArea = SizedBox(
        height: 180,
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
        height: 180,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          profileHeader,
          const SizedBox(height: 12),
          cardArea,
          const SizedBox(height: 12),
          // Book Title Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                    fontSize: 9,
                    color: AppColors.burgundy.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.selectedBookTitle ?? '제목 없음',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 인용구 (박스 없이 깔끔하게)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: quote.isNotEmpty
                ? Text(
                    '" $quote "',
                    style: TextStyle(
                      fontSize: 13, 
                      height: 1.6, 
                      color: AppColors.charcoal.withOpacity(0.9), 
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox(height: 48), // 빈 공간 유지
          ),
          const SizedBox(height: 8),
          // 페이지 수 
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— P.$totalPages',
              style: TextStyle(
                fontSize: 11, 
                color: AppColors.burgundy.withOpacity(0.8), 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
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
