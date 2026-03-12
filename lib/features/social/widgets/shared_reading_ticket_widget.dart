import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';

/// Shared Reading Ticket Widget
/// Redesigned to match the reference image with alternating card layouts,
/// circular nickname badges, prominent book covers and drawing areas.
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
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EB),
        borderRadius: BorderRadius.circular(4),
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
          ...members.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            final profile = memberProfiles[member.userId];
            final isFirst = index % 2 == 0;
            return _buildMemberSection(member, profile, isFirst, index + 1);
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Firenze',
            style: TextStyle(
              fontFamily: 'GreatVibes',
              fontSize: 28,
              color: AppColors.burgundy,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '함께 읽기',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: SizedBox(
        height: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(50, (i) {
            final w = i % 4 == 0 ? 3 : (i % 3 == 0 ? 1 : 2);
            return Container(
              width: w.toDouble(),
              color: AppColors.charcoal,
            );
          }),
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
    final bookTitle = member.selectedBookTitle ?? '';
    final drawingUrl = member.drawingUrl;
    final quote = member.quote ?? '';
    final totalPages = member.totalPages;

    // 책 표지 위젯
    final bookWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
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
        borderRadius: BorderRadius.circular(6),
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
          const SizedBox(height: 2),
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

    // 멤버 섹션 카드 (교차 레이아웃)
    Widget cardArea;
    if (bookOnLeft) {
      cardArea = SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 왼쪽: 책 표지
            Expanded(flex: 5, child: bookWidget),
            const SizedBox(width: 8),
            // 오른쪽: 닉네임 배지 + 그림
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
            // 왼쪽: 닉네임 배지 + 그림
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
            // 오른쪽: 책 표지
            Expanded(flex: 5, child: bookWidget),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 점선 구분선
          _buildDashedLine(),
          const SizedBox(height: 8),

          // 교차 카드 레이아웃
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

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashW = 6.0, gap = 4.0;
        final count = (constraints.maxWidth / (dashW + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dashW,
              height: 1,
              child: ColoredBox(color: AppColors.grey),
            ),
          ),
        );
      },
    );
  }
}
