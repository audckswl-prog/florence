import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';

/// Shared Reading Ticket Widget
/// Designed to look like a continuous receipt/ticket paper with:
/// - Paper that extends top & bottom (no rounded corners)
/// - Semicircular punch holes on both sides between member sections
/// - Dashed perforation lines (절취선) connecting the punch holes
/// - Cursive "Firenze" header
/// - Alternating book/drawing card layout
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
    return Container(
      // 둥근 모서리 없음 — 위아래로 연결된 느낌
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EB),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildBarcode(),
          ...members.asMap().entries.expand((entry) {
            final index = entry.key;
            final member = entry.value;
            final profile = memberProfiles[member.userId];
            final isFirst = index % 2 == 0;
            return [
              // 펀칭 + 절취선 (첫 번째 멤버 앞에도, 그 이후 멤버 사이에도)
              _buildPunchPerforationLine(),
              _buildMemberSection(member, profile, isFirst, index + 1),
            ];
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 양쪽 펀칭 반원 + 가운데 절취선 (점선)
  Widget _buildPunchPerforationLine() {
    const double punchRadius = 12.0;
    return SizedBox(
      height: punchRadius * 2,
      child: Stack(
        children: [
          // 가운데 절취선 (점선)
          Center(
            child: LayoutBuilder(
              builder: (_, constraints) {
                const dashW = 5.0, gap = 4.0;
                // 펀칭 반원 영역을 제외한 가운데 영역에 절취선
                final availableWidth = constraints.maxWidth - (punchRadius * 2);
                final count = (availableWidth / (dashW + gap)).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: dashW,
                      height: 1,
                      margin: EdgeInsets.symmetric(horizontal: gap / 2),
                      color: AppColors.grey.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
          ),
          // 왼쪽 펀칭 반원
          Positioned(
            left: -punchRadius,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: punchRadius * 2,
                height: punchRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(1, 0),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    // 배경색 투과 — 뒤의 배경이 보이도록
                    color: const Color(0xFFD5CFC9),
                  ),
                ),
              ),
            ),
          ),
          // 오른쪽 펀칭 반원
          Positioned(
            right: -punchRadius,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: punchRadius * 2,
                height: punchRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(-1, 0),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: const Color(0xFFD5CFC9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
    // 실제 바코드처럼 두께가 다른 검은 바들을 촘촘하게 배치
    // Code 128 스타일의 패턴 시뮬레이션
    const pattern = [
      2,1,1,3,1,2,1,1,3,1,2,2,1,1,1,3,2,1,1,2,1,1,3,1,1,2,2,1,
      1,3,1,1,2,1,3,1,1,2,1,1,2,3,1,1,1,2,1,3,1,2,1,1,2,1,1,3,
      1,2,1,1,3,2,1,1,1,2,3,1,1,2,1,1,1,3,2,1,1,2,1,3,1,1,2,1,
      1,2,1,3,1,1,2,1,1,1,3,2,1,1,2,1,3,1,2,1,1,2,1,1,3,1,2,1,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: SizedBox(
        height: 36,
        child: Row(
          children: pattern.asMap().entries.map((entry) {
            final i = entry.key;
            final w = entry.value;
            final isBar = i % 2 == 0; // 짝수 인덱스는 검은 바, 홀수는 흰 간격
            return SizedBox(
              width: w.toDouble(),
              child: isBar
                  ? Container(color: AppColors.charcoal)
                  : const SizedBox(),
            );
          }).toList(),
        ),
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

    // 책 표지 위젯
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
                child: const Center(
                  child: Icon(Icons.menu_book, color: AppColors.greyLight, size: 32),
                ),
              ),
            )
          : Container(
              color: AppColors.ivory,
              child: const Center(
                child: Icon(Icons.menu_book, color: AppColors.greyLight, size: 32),
              ),
            ),
    );

    // 그림 위젯
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
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.brush, color: Colors.orange, size: 28),
              ),
            )
          : const Center(
              child: Icon(Icons.brush, color: Colors.orange, size: 28),
            ),
    );

    // 닉네임 배지
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
            child: Icon(
              Icons.person,
              size: 16,
              color: AppColors.burgundy.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '닉네임 $memberIndex',
            style: TextStyle(
              fontSize: 8,
              color: AppColors.charcoal.withOpacity(0.5),
            ),
          ),
          Text(
            nickname,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    // 교차 카드 레이아웃
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
                children: [
                  nicknameBadge,
                  const SizedBox(height: 6),
                  Expanded(child: drawingWidget),
                ],
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
                children: [
                  nicknameBadge,
                  const SizedBox(height: 6),
                  Expanded(child: drawingWidget),
                ],
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

          // 페이지 수
          Align(
            alignment: bookOnLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Text(
              'P.$totalPages',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.charcoal.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 인용구
          if (quote.isNotEmpty)
            Text(
              '"$quote"',
              style: const TextStyle(
                fontSize: 11,
                height: 1.6,
                color: AppColors.charcoal,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
