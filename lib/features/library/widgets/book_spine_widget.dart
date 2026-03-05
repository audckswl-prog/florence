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

  const BookSpineWidget({super.key, required this.userBook});

  // 3가지 포인트 컬러 중 아이보리(베이지) 계열만 사용 (텍스트는 버건디)
  // 사용자가 제공한 사진의 베이스(오트밀/밝은 아이보리)를 바탕으로 미세하게 변형한 4가지 색상
  // 사용자가 지정한 3가지 색상과 제공된 사진의 베이스(오트밀) 색상 포함 총 4가지 색상
  Color _generateColor(String key) {
    final palettes = [
      const Color(0xFFEFECE4), // 1. Base Ivory (제공해주신 사진과 가장 유사한 기본 색상)
      const Color(0xFFF7E7CE), // 2. 사용자 지정 색상 #F7E7CE (밝은 베이지)
      const Color(0xFF36454F), // 3. 사용자 지정 색상 #36454F (어두운 차콜/그레이)
      const Color(0xFFD2B48C), // 4. 사용자 지정 색상 #D2B48C (중간 밝기 탄 컬러)
    ];

    // 웹 컴파일 환경에서 비트 연산(<< 5)이 32비트로 잘려 해시 충돌(같은 색상만 나옴)이 일어나는 버그 원천 차단
    // 소수(Prime) 1000000007를 이용해 안전한 모듈러 연산으로 문자열을 분산시킵니다.
    int hash = 0;
    for (int i = 0; i < key.length; i++) {
       hash = (hash * 31 + key.codeUnitAt(i)) % 1000000007; 
    }
    return palettes[hash % palettes.length];
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
    final double thickness = ((18.0 + (pages * 0.08)) * thicknessRatio).clamp(
      14.0,
      70.0,
    );
    final int readCount = userBook.readCount;

    // 텍스트 색상: 어두운 차콜색(#36454F)일 때만 흰색, 탄 컬러(#D2B48C) 등 나머지는 모두 검정색
    final Color textColor = bookColor == const Color(0xFF36454F) ? Colors.white : Colors.black;

    // 2. 세로 책 높이 (150px ~ 170px 사이에서 약간 불규칙하게 - 원래의 큼직한 스케일)
    final double bookHeight = 150.0 + (random.nextDouble() * 20.0);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              BookDetailModal(book: userBook.book, userBook: userBook),
        ).then((result) {
          if (result == true) {
            ref.invalidate(userBooksProvider);
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
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 2.0,
              ),
              child: RotatedBox(
                // 시계방향 90도 회전
                quarterTurns: 1,
                child: Text(
                  userBook.book.title,
                  textAlign: TextAlign.center, // 텍스트 자체가 가운데 정렬되도록 변경
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'Pretendard',
                    // 흰색 텍스트의 안티앨리어싱 빛 번짐 현상을 완벽히 통제하기 위해
                    // 두께를 극단적으로 얇은 w300(Light) 굵기로 조정하여 검은색(w600)과 균형을 맞춥니다.
                    fontWeight: textColor == Colors.white
                        ? FontWeight.w300
                        : FontWeight.w600,
                    // 두꺼운 책들은 모두 동일한 고정 폰트 크기(10.5)를 사용하도록 제한
                    // 아주 얇은 책인 경우에만 글씨가 잘리지 않게 점진적으로 작아지게 처리
                    fontSize: thickness > 28
                        ? 10.5
                        : (thickness > 20 ? 9.0 : 7.5),
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
        color, // Base
        Color.lerp(color, Colors.black, 0.05)!, // Right Base
        Color.lerp(color, Colors.black, 0.45)!, // Right Edge (Deep Shadow)
      ],
      stops: const [0.0, 0.3, 0.8, 1.0],
    );

    final Paint spinePaint = Paint()..shader = spineGradient.createShader(rect);

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
        canvas.drawLine(
          Offset(0, y),
          Offset(width, y),
          random.nextBool() ? darkHatch : lightHatch,
        );
      }
      for (double x = 0; x < width; x += 2.0) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, height),
          random.nextBool() ? darkHatch : lightHatch,
        );
      }

      final Paint bumpPaint = Paint()
        ..color = Colors.black.withOpacity(0.06)
        ..style = PaintingStyle.fill;
      int bumpCount = (width * height * 0.15).toInt();
      for (int i = 0; i < bumpCount; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            random.nextDouble() * width,
            random.nextDouble() * height,
            1.5,
            1.5,
          ),
          bumpPaint,
        );
      }
    } else if (textureStyle == 1) {
      // 2. 크라프트지/재생지 질감 (두번째 베이지색 책 느낌)
      final Paint noisePaint = Paint()
        ..color = Colors.black.withOpacity(0.04)
        ..style = PaintingStyle.fill;

      int density = (width * height * 0.4).toInt();
      for (int i = 0; i < density; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            random.nextDouble() * width,
            random.nextDouble() * height,
            1.0,
            1.0,
          ),
          noisePaint,
        );
      }

      final Paint darkFleck = Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      int fleckCount = (width * height * 0.005).toInt();
      for (int i = 0; i < fleckCount; i++) {
        double size = 1.0 + random.nextDouble() * 1.5;
        canvas.drawRect(
          Rect.fromLTWH(
            random.nextDouble() * width,
            random.nextDouble() * height,
            size,
            size,
          ),
          darkFleck,
        );
      }

      final Paint grain = Paint()
        ..color = Colors.black.withOpacity(0.02)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      for (double y = 0; y < height; y += 3.0) {
        if (random.nextBool())
          canvas.drawLine(Offset(0, y), Offset(width, y), grain);
      }
    } else {
      // 3. 매끄러운 무광 질감 (아래쪽 초록/검정 책 느낌)
      final Paint smoothNoise = Paint()
        ..color = Colors.black.withOpacity(0.03)
        ..style = PaintingStyle.fill;

      int density = (width * height * 0.2).toInt();
      for (int i = 0; i < density; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            random.nextDouble() * width,
            random.nextDouble() * height,
            1.0,
            1.0,
          ),
          smoothNoise,
        );
      }

      final Paint whiteNoise = Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < density / 2; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            random.nextDouble() * width,
            random.nextDouble() * height,
            1.0,
            1.0,
          ),
          whiteNoise,
        );
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
