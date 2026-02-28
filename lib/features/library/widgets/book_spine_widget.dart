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

    // 2. 세로 책 높이 (150px ~ 170px 사이에서 약간 불규칙하게)
    final double bookHeight = 150.0 + (random.nextDouble() * 20.0);

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
      child: SizedBox(
        width: thickness, // 두께가 곧 너비가 됨
        height: bookHeight, // 약간 랜덤한 세로 높이
        child: CustomPaint(
          painter: BookSpinePainter(
            color: bookColor,
            thickness: thickness,
            readCount: readCount,
            textureStyle: userBook.isbn.hashCode.abs() % 3,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 2.0),
              child: RotatedBox(
                // 90도 회전하여 텍스트를 위에서 아래로 읽도록 고정 (quarterTurns: 1)
                quarterTurns: 1,
                child: Text(
                  userBook.book.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: thickness > 30 ? 11 : 9, // 두께에 비례해서 폰트 크기 미세 조정
                    height: 1.1,
                    letterSpacing: -0.2,
                  ),
                  maxLines: thickness > 45 ? 2 : 1, // 엄청 두꺼운 책은 2줄 허용
                  overflow: TextOverflow.ellipsis,
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
  final int readCount;
  final int textureStyle;

  BookSpinePainter({
    required this.color,
    required this.thickness,
    this.readCount = 1,
    this.textureStyle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBook3D(canvas, size);
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
    // 세로로 서 있는 책이므로 그라데이션은 왼쪽 힌지에서 오른쪽으로 자연스럽게
    final spineGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.lerp(color, Colors.black, 0.3)!,  // Left Edge (Shadow, Hinge point)
        Color.lerp(color, Colors.white, 0.05)!, // Left slight highlight
        color,                                  // Base
        Color.lerp(color, Colors.black, 0.05)!, // Right Base
        Color.lerp(color, Colors.black, 0.45)!, // Right Edge (Deep Shadow)
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

    // ── 4. 힌지 (홈) 디테일 - 왼쪽(책등 접히는 곳)에 세로줄 형태로 추가 ──
    final double hingeOffset = 8.0; // 너무 안쪽으로 들어오지 않게
    
    if (w > hingeOffset + 4.0) { // 책이 너무 얇으면 힌지를 안그림
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
    }

    // ── 5. N-th Reading Marker ──
    // 질감(Texture) 위에 그려져야 하므로 맨 마지막에 그림 (수평선 형태)
    if (readCount > 1) {
      final Paint markerPaint = Paint()
        ..color = AppColors.charcoal.withOpacity(0.4) // 약간 어두운 색으로 은은하게
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
        
      // 맨 위에 수평선 형태로 그리기
      final double startY = 12.0; 
      
      canvas.save();
      // 책 너비(두께)를 가로지르는 선을 그리기 위해 padding을 줍니다.
      final double linePaddingX = w * 0.15; // 좌우 여백
      
      int linesToDraw = readCount > 5 ? 5 : readCount;
      for (int i = 0; i < linesToDraw; i++) {
        // 수평선 (가로줄)을 아래로 내려가면서 그립니다.
        double currentY = startY + (i * 4.0);
        canvas.drawLine(
          Offset(linePaddingX, currentY), 
          Offset(w - linePaddingX, currentY), 
          markerPaint
        );
      }
      
      // 5회 이상인 경우 마지막 선 아래에 작은 '+' 표시 추가
      if (readCount > 5) {
        final Paint plusPaint = Paint()
          ..color = AppColors.charcoal.withOpacity(0.4)
          ..strokeWidth = 1.0;
          
        double plusY = startY + (5 * 4.0);
        double centerX = w / 2;
        
        canvas.drawLine(Offset(centerX - 2, plusY), Offset(centerX + 2, plusY), plusPaint);
        canvas.drawLine(Offset(centerX, plusY - 2), Offset(centerX, plusY + 2), plusPaint);
      }
      
      canvas.restore();
    }
  }

  // 노이즈 & 질감 텍스처 그리기 (레퍼런스 이미지의 3가지 질감 구현)
  void _drawTexture(Canvas canvas, double width, double height) {
    final random = Random((width * height).toInt());
    
    if (textureStyle == 0) {
      // 1. 거친 패브릭/천 질감 (맨 위 갈색 책 느낌)
      final Paint darkHatch = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final Paint lightHatch = Paint()
        ..color = Colors.white.withOpacity(0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (double y = 0; y < height; y += 2.0) {
        canvas.drawLine(Offset(0, y), Offset(width, y), random.nextBool() ? darkHatch : lightHatch);
      }
      for (double x = 0; x < width; x += 2.0) {
        canvas.drawLine(Offset(x, 0), Offset(x, height), random.nextBool() ? darkHatch : lightHatch);
      }
      
      final Paint bumpPaint = Paint()
        ..color = Colors.black.withOpacity(0.06)
        ..style = PaintingStyle.fill;
      int bumpCount = (width * height * 0.15).toInt();
      for (int i = 0; i < bumpCount; i++) {
         canvas.drawRect(Rect.fromLTWH(random.nextDouble() * width, random.nextDouble() * height, 1.5, 1.5), bumpPaint);
      }
    } else if (textureStyle == 1) {
      // 2. 크라프트지/재생지 질감 (두번째 베이지색 책 느낌)
      final Paint noisePaint = Paint()
        ..color = Colors.black.withOpacity(0.04)
        ..style = PaintingStyle.fill;
      
      int density = (width * height * 0.4).toInt();
      for (int i = 0; i < density; i++) {
        canvas.drawRect(Rect.fromLTWH(random.nextDouble() * width, random.nextDouble() * height, 1.0, 1.0), noisePaint);
      }

      final Paint darkFleck = Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      int fleckCount = (width * height * 0.005).toInt();
      for (int i = 0; i < fleckCount; i++) {
        double size = 1.0 + random.nextDouble() * 1.5;
        canvas.drawRect(Rect.fromLTWH(random.nextDouble() * width, random.nextDouble() * height, size, size), darkFleck);
      }
      
      final Paint grain = Paint()
        ..color = Colors.black.withOpacity(0.02)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      for (double y = 0; y < height; y += 3.0) {
        if(random.nextBool()) canvas.drawLine(Offset(0, y), Offset(width, y), grain);
      }
    } else {
      // 3. 매끄러운 무광 질감 (아래쪽 초록/검정 책 느낌)
      final Paint smoothNoise = Paint()
        ..color = Colors.black.withOpacity(0.03)
        ..style = PaintingStyle.fill;
        
      int density = (width * height * 0.2).toInt();
      for (int i = 0; i < density; i++) {
        canvas.drawRect(Rect.fromLTWH(random.nextDouble() * width, random.nextDouble() * height, 1.0, 1.0), smoothNoise);
      }
      
      final Paint whiteNoise = Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < density / 2; i++) {
        canvas.drawRect(Rect.fromLTWH(random.nextDouble() * width, random.nextDouble() * height, 1.0, 1.0), whiteNoise);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BookSpinePainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.thickness != thickness ||
           oldDelegate.textureStyle != textureStyle;
  }
}
