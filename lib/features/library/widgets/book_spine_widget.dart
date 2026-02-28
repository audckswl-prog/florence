import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_book_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'book_detail_modal.dart';
import '../providers/library_providers.dart';
import '../widgets/reading_completion_dialog.dart';
import '../screens/reading_ticket_screen.dart';

class BookSpineWidget extends ConsumerWidget {
  final UserBook userBook;

  const BookSpineWidget({
    super.key,
    required this.userBook,
  });

  // 3가지 포인트 컬러 중 아이보리(베이지) 계열만 사용 (텍스트는 버건디)
  Color _generateColor(String key) {
    final random = Random(key.hashCode);
    final palettes = [
      // 1. Duomo Terracotta (The Dome Tiles) - Warm, Earthy Orange-Reds
      const Color(0xFFD97C63), // Light Terracotta
      const Color(0xFFC86B54), // Brick Red
      const Color(0xFFE08E79), // Faded Roof Tile
      const Color(0xFFCD5C5C), // Indian Red (Classic)

      // 2. Marble White (The Ribs & Facade) - Warm Off-Whites
      const Color(0xFFE8E2D2), // Marble White
      const Color(0xFFDFD7C4), // Aged Marble
      const Color(0xFFF0EBE0), // Clean Marble
      const Color(0xFFE6DBC6), // Warm Stone

      // 3. Florence Stone (The Lantern & Structure) - Greige/Sand
      const Color(0xFFC7B9A5), // Sandstone
      const Color(0xFFD4C9BD), // Greyish Beige
      const Color(0xFFBDB298), // Old Stone
      const Color(0xFFC0B296), // Khaki Stone
    ];
    return palettes[random.nextInt(palettes.length)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookColor = _generateColor(userBook.isbn);
    final random = Random(userBook.isbn.hashCode);

    // 1. 두께 계산 (기본 두께)
    int pages = userBook.book.pageCount;
    if (pages == 0) pages = 200 + random.nextInt(400); 
    
    // N회독, 부분 독서 반영
    final int readPages = userBook.readPages;
    final int totalPages = userBook.totalPages ?? pages;
    
    double thicknessRatio = 1.0;
    if (readPages > 0 && totalPages > 0 && readPages <= totalPages) {
      thicknessRatio = readPages / totalPages;
    }

    // 최소 두께: 12.0 (너무 얇아지면 안 보이므로), 최대 64.0
    final double thickness = ((15.0 + (pages * 0.07)) * thicknessRatio).clamp(12.0, 64.0);
    final int readCount = userBook.readCount;

    // 텍스트 색상: 항상 버건디 (브랜드 아이덴티티)
    const isDark = false; 
    const textColor = AppColors.burgundy;

    // 2. 너비 다양성 (55% ~ 65%)
    final double widthFactor = 0.55 + random.nextDouble() * 0.10;
    
    // 3. 오프셋 (좌우 -10px ~ +10px)
    final double offsetX = (random.nextDouble() - 0.5) * 20.0;

    // 4. 회전 방향
    final bool showSpineOnRight = random.nextBool();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BookDetailModal(
            book: userBook.book,
            userBook: userBook,
          ),
        ).then((result) async {
          if (result == true) {
            ref.invalidate(userBooksProvider);
          } else if (result is Map<String, dynamic> && result['action'] == 'read_completed') {
            final nav = Navigator.of(context);
            ref.invalidate(userBooksProvider);
            final mockUserBook = result['book'];
            final quote = await showDialog<String>(
              context: context,
              builder: (context) => ReadingCompletionDialog(userBook: mockUserBook),
            );
            
            if (quote != null) {
              nav.push(
                MaterialPageRoute(
                   builder: (context) => ReadingTicketScreen(
                     userBook: mockUserBook,
                     quote: quote,
                   ),
                ),
              );
            }
          }
        });
      },
      child: Transform.translate(
        offset: Offset(offsetX, 0),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: SizedBox(
              height: thickness,
              child: CustomPaint(
                painter: BookSpinePainter(
                  color: bookColor,
                  thickness: thickness,
                  showSpineOnRight: showSpineOnRight,
                  readCount: readCount,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      userBook.book.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: thickness > 40 ? 12 : 10,
                        height: 1.1,
                        letterSpacing: -0.2,
                        shadows: [
                          // Debossed (음각) text effect
                          Shadow(
                            color: Colors.white.withOpacity(0.5),
                            offset: const Offset(0, 1.0),
                            blurRadius: 0,
                          ),
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, -1.0),
                            blurRadius: 1.0,
                          ),
                        ],
                      ),
                      maxLines: thickness > 45 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BookSpinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool showSpineOnRight;
  final int readCount;

  BookSpinePainter({
    required this.color,
    required this.thickness,
    required this.showSpineOnRight,
    this.readCount = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showSpineOnRight) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
      _drawBook3D(canvas, size);
      canvas.restore();
    } else {
      _drawBook3D(canvas, size);
    }
  }

  void _drawBook3D(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Geometry Constants ──
    // 끝이 너무 각지다는 피드백 반영: 살짝 둥글게 처리 (2.0px)
    const Radius cornerRadius = Radius.circular(2.0);
    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final RRect rrect = RRect.fromRectAndRadius(rect, cornerRadius);

    // ── 1. 그림자 (Drop Shadow) ──
    final Path shadowPath = Path()..addRRect(rrect);

    canvas.drawPath(
      shadowPath.shift(const Offset(0, 2)), // 그림자는 살짝만
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── 2. 책등 앞면 (Spine Face) ──
    // 그라데이션 - 원통형보다는 평면적이고 끝에만 살짝 어두운 느낌 (레퍼런스 스타일)
    final spineGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(color, Colors.black, 0.35)!, // Top Edge (Shadow)
        Color.lerp(color, Colors.white, 0.05)!, // Upper slight highlight
        color,                                  // Base
        Color.lerp(color, Colors.black, 0.1)!,  // Lower Base
        Color.lerp(color, Colors.black, 0.5)!,  // Bottom Edge (Deep Shadow)
      ],
      stops: const [0.0, 0.08, 0.5, 0.9, 1.0],
    );

    final Paint spinePaint = Paint()
      ..shader = spineGradient.createShader(rect);

    // 둥근 사각형으로 그림
    canvas.drawRRect(rrect, spinePaint);

    // ── 2.5 텍스처 (Texture) - 종이/천 질감 추가 ──
    // 텍스처가 둥근 모서리를 넘지 않도록 클리핑 적용
    canvas.save();
    canvas.clipRRect(rrect);
    _drawTexture(canvas, w, h);
    canvas.restore();

    // ── 4. 힌지 (홈) 디테일 - 더 깊이감 있게 ──
    final double hingeOffset = 14.0;
    
    // Groove Shadow
    canvas.drawLine(
      Offset(hingeOffset, 0),
      Offset(hingeOffset, h),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );

    // Groove Highlight
    canvas.drawLine(
      Offset(hingeOffset + 1.5, 0),
      Offset(hingeOffset + 1.5, h),
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..strokeWidth = 0.5,
    );

    // ── 5. N-th Reading Marker ──
    if (readCount > 1) {
      final Paint markerPaint = Paint()
        ..color = AppColors.burgundy.withOpacity(0.7)
        ..style = PaintingStyle.fill;
        
      // Draw small diamond or dot at the top/bottom 
      final double markerY = h - 16.0; // Draw near the bottom of the spine
      final double markerX = w / 2;
      
      canvas.save();
      canvas.translate(markerX, markerY);
      
      // Draw a small decorative stack of dots based on readCount
      // Max out at 5 dots so it doesn't look messy
      int dotsToDraw = readCount > 5 ? 5 : readCount;
      for (int i = 0; i < dotsToDraw; i++) {
        canvas.drawCircle(Offset(0, -i * 6.0), 1.5, markerPaint);
      }
      
      // If read > 5, draw a small '+' at the top
      if (readCount > 5) {
        final Paint plusPaint = Paint()
          ..color = AppColors.burgundy.withOpacity(0.7)
          ..strokeWidth = 1.0;
        double lineY = -dotsToDraw * 6.0;
        canvas.drawLine(Offset(-2, lineY), Offset(2, lineY), plusPaint);
        canvas.drawLine(Offset(0, lineY - 2), Offset(0, lineY + 2), plusPaint);
      }
      
      canvas.restore();
    }
  }

  // 노이즈 & 질감 텍스처 그리기 (레퍼런스 이미지와 같은 켄트지/패브릭 질감)
  void _drawTexture(Canvas canvas, double width, double height) {
    // 고정적인 질감을 위해 크기 기반의 시드 사용
    final random = Random((width * height).toInt());
    
    // 1. 강한 기본 노이즈 (종이/천의 미세한 구멍 및 돌기)
    final Paint darkNoise = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final Paint lightNoise = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
      
    // 밀도를 높게 설정하여 오돌토돌한 느낌을 극대화
    final int noiseCount = (width * height * 0.8).toInt().clamp(500, 10000);
    for (int i = 0; i < noiseCount; i++) {
      double x = random.nextDouble() * width;
      double y = random.nextDouble() * height;
      Paint p = random.nextBool() ? darkNoise : lightNoise;
      // 점의 크기를 살짝 키워 질감 입자를 강조
      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), p);
    }

    // 2. 패브릭/천 직조 질감 (Cross-hatch pattern)
    // 얇은 가로/세로 선을 촘촘하게 그려 직물 느낌을 추가
    final Paint hThreadInfo = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
      
    final Paint vThreadInfo = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 가로 스레드
    for (double y = 0; y < height; y += 1.8) {
      if (random.nextDouble() > 0.15) { // 약간씩 끊어지는 느낌
        canvas.drawLine(
          Offset(0, y + (random.nextDouble() * 0.5)), 
          Offset(width, y + (random.nextDouble() * 0.5)), 
          hThreadInfo
        );
      }
    }

    // 세로 스레드
    for (double x = 0; x < width; x += 1.8) {
      if (random.nextDouble() > 0.15) {
        canvas.drawLine(
          Offset(x + (random.nextDouble() * 0.5), 0), 
          Offset(x + (random.nextDouble() * 0.5), height), 
          vThreadInfo
        );
      }
    }

    // 3. 종이의 불순물/먼지 같은 약간 큰 점들 추가
    final Paint fleckPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.fill;
      
    final int fleckCount = (width * height * 0.003).toInt();
    for (int i = 0; i < fleckCount; i++) {
      double x = random.nextDouble() * width;
      double y = random.nextDouble() * height;
      double size = 1.5 + random.nextDouble() * 1.5;
      canvas.drawRect(Rect.fromLTWH(x, y, size, size), fleckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BookSpinePainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.thickness != thickness ||
           oldDelegate.showSpineOnRight != showSpineOnRight;
  }
}
