import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_book_model.dart';
import '../../../data/models/book_model.dart';
import '../providers/ai_ticket_provider.dart';
import '../providers/library_providers.dart';

class ReadingTicketScreen extends ConsumerStatefulWidget {
  final UserBook userBook;
  final String quote;

  const ReadingTicketScreen({
    super.key,
    required this.userBook,
    required this.quote,
  });

  @override
  ConsumerState<ReadingTicketScreen> createState() => _ReadingTicketScreenState();
}

class _ReadingTicketScreenState extends ConsumerState<ReadingTicketScreen> {
  // Generated once per screen open — stays consistent during the session
  late final Alignment _bgAlignment;
  late final Color _bgTint;

  // Curated romantic / warm palette for tint overlays
  static const _tints = [
    Color(0xFFE57373), // dusty red
    Color(0xFFBA68C8), // muted purple
    Color(0xFF4DB6AC), // teal
    Color(0xFF64B5F6), // sky blue
    Color(0xFFFFB74D), // amber
    Color(0xFFF06292), // pink
    Color(0xFF81C784), // sage green
    Color(0xFF90A4AE), // slate blue-grey
    Color(0xFFFF8A65), // terracotta
    Color(0xFFA1887F), // warm brown
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    // x and y each range from -0.7 to 0.7 for subtle pan effect
    _bgAlignment = Alignment(
      (rng.nextDouble() * 1.4) - 0.7,
      (rng.nextDouble() * 1.4) - 0.7,
    );
    _bgTint = _tints[rng.nextInt(_tints.length)];
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.userBook.book;
    final aiDataAsync = ref.watch(aiTicketFutureProvider(book));
    final readCountThisYear = ref.watch(readBooksThisYearProvider).value ?? 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 32),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: Florence panorama with random alignment + blur + color tint
          Image.asset(
            'assets/images/florence_bg.jpg',
            fit: BoxFit.cover,
            alignment: _bgAlignment, // Random pan — different every ticket session
            width: double.infinity,
            height: double.infinity,
          ),
          // Blur layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
          // Random color tint overlay (semi-transparent)
          Container(color: _bgTint.withOpacity(0.30)),

          // Ticket centered horizontally, full height vertically
          Align(
            alignment: Alignment.center,
            child: SizedBox.expand(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Hero(
                      tag: 'ticket_${book.isbn}',
                        child: aiDataAsync.when(
                          data: (aiData) => ReadingTicketWidget(
                            userBook: widget.userBook,
                            quote: widget.quote,
                            readCountThisYear: readCountThisYear,
                            nationalityCode: aiData.nationalityCode,
                            nationalityName: aiData.nationalityName,
                            publicationYear: aiData.publicationYear != '연도 미상' 
                                ? aiData.publicationYear 
                                : book.publicationYear,
                          ),
                          loading: () => ReadingTicketWidget(
                            userBook: widget.userBook,
                            quote: widget.quote,
                            readCountThisYear: readCountThisYear,
                            nationalityCode: 'UN',
                            nationalityName: '분석 중',
                            publicationYear: book.publicationYear,
                          ),
                          error: (e, st) => ReadingTicketWidget(
                            userBook: widget.userBook,
                            quote: widget.quote,
                            readCountThisYear: readCountThisYear,
                            nationalityCode: 'UN',
                            nationalityName: '알 수 없음',
                            publicationYear: book.publicationYear,
                          ),
                        ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final aiTicketFutureProvider = FutureProvider.family.autoDispose((ref, Book book) {
  final repo = ref.watch(aiTicketRepositoryProvider);
  return repo.getTicketMetadata(book.isbn, book.title, book.author);
});

class ReadingTicketWidget extends StatelessWidget {
  final UserBook userBook;
  final String quote;
  final int readCountThisYear;
  final String nationalityCode;
  final String nationalityName;
  final String publicationYear;

  const ReadingTicketWidget({
    required this.userBook,
    required this.quote,
    required this.readCountThisYear,
    required this.nationalityCode,
    required this.nationalityName,
    required this.publicationYear,
  });

  String _flagEmoji(String code) {
    if (code.length != 2) return '🌐';
    return String.fromCharCode(code.codeUnitAt(0) - 0x41 + 0x1F1E6) +
        String.fromCharCode(code.codeUnitAt(1) - 0x41 + 0x1F1E6);
  }

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;
    final pageNum = userBook.totalPages ?? book.pageCount;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // Heights dynamically include device's safe area (notch / home bar)
    final double topH = 80.0 + safeTop;
    final double botH = 88.0 + safeBottom;

    return ClipPath(
      clipper: TicketClipper(topCutoutY: topH, bottomCutoutY: botH),
      child: SizedBox.expand(
        child: ColoredBox(
          color: const Color(0xFFF0F0F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── TOP (barcode) ──────────────────────────────────────
              SizedBox(
                height: topH,
                child: Padding(
                  padding: EdgeInsets.only(top: safeTop),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(36, (i) {
                              final w = Random(i).nextInt(4) + 1;
                              return Container(width: w.toDouble(), color: AppColors.charcoal);
                            }),
                          ),
                        ),
                      ),
                      const DashedLine(),
                    ],
                  ),
                ),
              ),

              // ── MIDDLE (content) ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Travel count + Gate icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '올해의 ${readCountThisYear}번째 여행',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.charcoal,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Transform.rotate(
                                angle: pi / 4,
                                child: const Icon(Icons.flight, size: 26, color: AppColors.black),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'GATE',
                                style: GoogleFonts.lato(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Flag + country / year
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12, width: 0.5),
                                ),
                                child: Image.network(
                                  'https://flagcdn.com/w80/${nationalityCode.toLowerCase()}.png',
                                  width: 40,
                                  height: 26,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Text(_flagEmoji(nationalityCode), style: const TextStyle(fontSize: 24)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$nationalityName, $publicationYear',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Spacer(flex: 1),

                      // Book cover — shrinks gracefully on small screens
                      Flexible(
                        flex: 16,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 290, maxWidth: 190),
                            child: AspectRatio(
                              aspectRatio: 1 / 1.45,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: book.coverUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Page number
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'P.${pageNum > 0 ? pageNum : "???"}',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Quote (scrollable if it's very long)
                      if (quote.isNotEmpty)
                        Flexible(
                          flex: 6,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              '"$quote"',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 11,
                                height: 1.55,
                                color: AppColors.charcoal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),

              // ── BOTTOM (Firenze + button) ─────────────────────────
              SizedBox(
                height: botH,
                child: Padding(
                  padding: EdgeInsets.only(bottom: safeBottom),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const DashedLine(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Firenze',
                                style: GoogleFonts.greatVibes(
                                  fontSize: 30,
                                  color: AppColors.burgundy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  foregroundColor: AppColors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                child: const Text(
                                  '독서앱 설치하기',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashed divider ──────────────────────────────────────────────────
class DashedLine extends StatelessWidget {
  const DashedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (_, constraints) {
          const dashW = 7.0, gap = 5.0;
          final count = (constraints.maxWidth / (dashW + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => SizedBox(
                width: dashW,
                height: 1,
                child: ColoredBox(color: AppColors.charcoal.withOpacity(0.8)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Ticket-shaped clip (half-circle notches on sides) ────────────────
class TicketClipper extends CustomClipper<Path> {
  final double topCutoutY;
  final double bottomCutoutY;

  const TicketClipper({required this.topCutoutY, required this.bottomCutoutY});

  @override
  Path getClip(Size size) {
    const r = 10.0;
    final p = Path();

    p.moveTo(0, 0);
    p.lineTo(size.width, 0);

    // right top notch
    p.lineTo(size.width, topCutoutY - r);
    p.arcTo(Rect.fromCircle(center: Offset(size.width, topCutoutY), radius: r), -pi / 2, -pi, false);

    // right bottom notch
    p.lineTo(size.width, size.height - bottomCutoutY - r);
    p.arcTo(Rect.fromCircle(center: Offset(size.width, size.height - bottomCutoutY), radius: r), -pi / 2, -pi, false);

    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);

    // left bottom notch
    p.lineTo(0, size.height - bottomCutoutY + r);
    p.arcTo(Rect.fromCircle(center: Offset(0, size.height - bottomCutoutY), radius: r), pi / 2, -pi, false);

    // left top notch
    p.lineTo(0, topCutoutY + r);
    p.arcTo(Rect.fromCircle(center: Offset(0, topCutoutY), radius: r), pi / 2, -pi, false);

    p.close();
    return p;
  }

  @override
  bool shouldReclip(TicketClipper old) =>
      old.topCutoutY != topCutoutY || old.bottomCutoutY != bottomCutoutY;
}
