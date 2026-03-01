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

    // 최소 두께: 14.0 (얇은 책), 최대 70.0 (적당히 두꺼운 책)
    final double thickness = ((18.0 + (pages * 0.08)) * thicknessRatio).clamp(14.0, 70.0);
    final int readCount = userBook.readCount;

    // 텍스트 색상: 항상 버건디 (브랜드 아이덴티티)
    const isDark = false; 
    const textColor = AppColors.burgundy;

    // 2. 세로 책 높이 (150px ~ 170px 사이에서 약간 불규칙하게 - 원래의 큼직한 스케일)
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
          child: Align(
            alignment: Alignment.center, // 중앙에서부터 텍스트 배치
            child: Padding(
              // 다시 큰 스케일로 돌아왔으므로 기본 패딩 복구
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
              child: RotatedBox(
                // 시계방향 90도 회전
                quarterTurns: 1,
                child: Text(
                  userBook.book.title,
                  textAlign: TextAlign.center, // 텍스트 자체가 가운데 정렬되도록 변경
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    // 폰트 크기 역시 원래처럼 큼직하게 복구
                    fontSize: thickness > 34 ? 12.0 : 9.5,
                    height: 1.1,
                    letterSpacing: -0.2,
                  ),
                  maxLines: thickness > 48 ? 2 : 1,
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
    // 세로로 섰을 때의 바탕 면 (입체감을 위한 좌우 약간의 음영)
    final spineGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.lerp(color, Colors.white, 0.05)!, // Left slight highlight
        color,                                  // Base
        Color.lerp(color, Colors.black, 0.05)!, // Right Base
        Color.lerp(color, Colors.black, 0.45)!, // Right Edge (Deep Shadow)
      ],
      stops: const [0.0, 0.3, 0.8, 1.0],
    );

    final Paint spinePaint = Paint()
      ..shader = spineGradient.createShader(rect);

    canvas.drawRRect(rrect, spinePaint);

    // ── 3. 텍스처 (Texture) - 종이/천 질감 추가 ──
    canvas.save();
    canvas.clipRRect(rrect);
    _drawTexture(canvas, w, h);
    canvas.restore();

    // 힌지 및 마커 관련 코드는 사용자 요청으로 모두 제거됨
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
