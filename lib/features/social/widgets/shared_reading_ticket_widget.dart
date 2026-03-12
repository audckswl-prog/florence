import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';

/// Shared Reading Ticket Widget
/// Displays all members' quotes and drawings in a single, long ticket
/// with alternating left/right layout for each member section.
class SharedReadingTicketWidget extends StatelessWidget {
  final Project project;
  final List<ProjectMember> members;
  final Map<String, Profile> memberProfiles; // userId -> Profile

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
        color: const Color(0xFFF5F0EB), // paper color
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
          // ── HEADER ──
          _buildHeader(),

          // ── BARCODE ──
          _buildBarcode(),

          // ── MEMBER SECTIONS (alternating layout) ──
          ...members.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            final profile = memberProfiles[member.userId];
            final isEven = index % 2 == 0;
            return _buildMemberSection(member, profile, isEven, index + 1);
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Firenze',
            style: TextStyle(
              fontFamily: 'GreatVibes',
              fontSize: 32,
              color: AppColors.burgundy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '함께 읽기',
            style: TextStyle(
              fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 30,
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
    bool drawingOnLeft,
    int memberIndex,
  ) {
    final nickname = profile?.nickname ?? 'Member ${member.userId.substring(0, 4)}';
    final bookCover = member.selectedBookCover;
    final drawingUrl = member.drawingUrl;
    final quote = member.quote ?? '';

    // Drawing widget
    final drawingWidget = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4), // yellow canvas
        borderRadius: BorderRadius.circular(4),
      ),
      child: drawingUrl != null && drawingUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                drawingUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.brush, color: Colors.orange, size: 32),
                ),
              ),
            )
          : const Center(
              child: Icon(Icons.brush, color: Colors.orange, size: 32),
            ),
    );

    // Book cover widget
    final bookWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: bookCover != null && bookCover.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(bookCover, fit: BoxFit.cover),
            )
          : const Center(
              child: Icon(Icons.menu_book, color: AppColors.greyLight),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashed divider
          _buildDashedLine(),
          const SizedBox(height: 6),

          // Nickname label
          Row(
            children: [
              Text(
                '닉네임 $memberIndex',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.charcoal.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                nickname,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Drawing + Book Cover row (alternating)
          SizedBox(
            height: 110,
            child: Row(
              children: drawingOnLeft
                  ? [
                      Expanded(flex: 5, child: drawingWidget),
                      const SizedBox(width: 8),
                      Expanded(flex: 4, child: bookWidget),
                    ]
                  : [
                      Expanded(flex: 4, child: bookWidget),
                      const SizedBox(width: 8),
                      Expanded(flex: 5, child: drawingWidget),
                    ],
            ),
          ),
          const SizedBox(height: 4),

          // Page number
          Text(
            'P.${member.selectedIsbn != null ? member.selectedIsbn!.substring(member.selectedIsbn!.length - 3) : "???"}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),

          // Quote
          if (quote.isNotEmpty)
            Text(
              '"$quote"',
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.charcoal,
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
