import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class DrawingCanvasScreen extends StatefulWidget {
  const DrawingCanvasScreen({super.key});

  @override
  State<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  final List<_DrawingStroke> _strokes = [];
  _DrawingStroke? _currentStroke;
  Color _currentColor = AppColors.charcoal;
  double _strokeWidth = 5.0;
  bool _isEraser = false;
  final GlobalKey _canvasKey = GlobalKey();

  static const Color _canvasBgColor = Color(0xFFF0EAE1);
  static const List<Color> _palette = [
    AppColors.charcoal, // Graphite / Black Ink
    AppColors.burgundy, // Signature Firenze Wine
    Color(0xFF2B4D6A),  // Vintage Navy Ink
    Color(0xFF4A5C46),  // Classic Olive Green
    Color(0xFF987B5B),  // Sepia / Camel Brown
  ];

  @override
  void initState() {
    super.initState();
    // 상단바/네비바 숨기기 (옵션 - 몰입감 증대)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 모든 방향 회전 허용 (기기 설정에 따름)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // 세로 모드로 원복
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // 시스템 UI 복구
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // 배경을 더 어둡게 하여 캔버스 강조
      appBar: isLandscape
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '구절을 그림으로 그려주세요',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveAndReturn,
            child: const Text(
              '완료',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // Layout Modes
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPortraitLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.screen_rotation, size: 64, color: Colors.white70),
          const SizedBox(height: 24),
          const Text(
            '화면을 가로로 돌려\n그림을 그려주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Stack(
      children: [
        // 스케치 영역 (가운데 정렬, 남는 공간을 최대로 채움)
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildCanvasArea(),
          ),
        ),

        // 상단 안내 텍스트
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Text(
              '구절을 그림으로 그려주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 좌측 도구 모음 (플로팅 패널 느낌)
        Positioned(
          left: 16,
          top: 8,
          bottom: 8,
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '닫기',
                ),
                const Spacer(),
                _buildUndoButton(),
                const SizedBox(height: 16),
                _buildEraserButton(isVertical: true),
                const SizedBox(height: 16),
                _buildStrokeWidths(isVertical: true),
              ],
            ),
          ),
        ),

        // 우측 도구 모음 (플로팅 패널 느낌)
        Positioned(
          right: 16,
          top: 8,
          bottom: 8,
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                TextButton(
                  onPressed: _saveAndReturn,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('완료', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Spacer(),
                ..._palette.map((color) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: _buildColorButton(color),
                )).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // Components
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildCanvasArea() {
    return AspectRatio(
      aspectRatio: 4 / 3, // 가로가 넓은 4:3 비율 고정
      child: Container(
        decoration: BoxDecoration(
          color: _canvasBgColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: RepaintBoundary(
            key: _canvasKey,
            child: Container(
              color: _canvasBgColor,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = _DrawingStroke(
                      color: _isEraser ? _canvasBgColor : _currentColor,
                      strokeWidth: _isEraser ? _strokeWidth * 3 : _strokeWidth,
                    );
                    _currentStroke!.points.add(details.localPosition);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke?.points.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    if (_currentStroke != null) {
                      _strokes.add(_currentStroke!);
                      _currentStroke = null;
                    }
                  });
                },
                child: CustomPaint(
                  painter: _DrawingPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUndoButton() {
    return IconButton(
      onPressed: () {
        if (_strokes.isNotEmpty) {
          setState(() => _strokes.removeLast());
        }
      },
      icon: const Icon(Icons.undo, color: Colors.white, size: 28),
    );
  }

  Widget _buildEraserButton({required bool isVertical}) {
    return GestureDetector(
      onTap: () => setState(() => _isEraser = !_isEraser),
      child: Container(
        padding: isVertical
            ? const EdgeInsets.all(12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isEraser ? AppColors.burgundy : Colors.white12,
          shape: isVertical ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isVertical ? null : BorderRadius.circular(20),
        ),
        child: isVertical
            ? Icon(
                Icons.cleaning_services_rounded,
                color: _isEraser ? Colors.white : Colors.white70,
                size: 24,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cleaning_services_rounded,
                    color: _isEraser ? Colors.white : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '지우개',
                    style: TextStyle(
                      color: _isEraser ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStrokeWidths({required bool isVertical}) {
    final children = [
      _buildThicknessButton(2.0),
      SizedBox(width: isVertical ? 0 : 8, height: isVertical ? 8 : 0),
      _buildThicknessButton(5.0),
      SizedBox(width: isVertical ? 0 : 8, height: isVertical ? 8 : 0),
      _buildThicknessButton(10.0),
    ];

    return isVertical
        ? Column(children: children)
        : Row(children: children);
  }

  Widget _buildThicknessButton(double width) {
    final isSelected = _strokeWidth == width;
    return GestureDetector(
      onTap: () => setState(() => _strokeWidth = width),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: width * 1.5,
          height: width * 1.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = !_isEraser && _currentColor == color;
    return GestureDetector(
      onTap: () => setState(() {
        _currentColor = color;
        _isEraser = false;
      }),
      child: Container(
        width: isSelected ? 40 : 32,
        height: isSelected ? 40 : 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
      ),
    );
  }

  Future<void> _saveAndReturn() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그림을 그려주세요!')),
      );
      return;
    }

    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      if (mounted) {
        Navigator.of(context).pop(pngBytes);
      }
    } catch (e) {
      debugPrint('Error saving drawing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
        );
      }
    }
  }
}

class _DrawingStroke {
  final List<Offset> points = [];
  final Color color;
  final double strokeWidth;

  _DrawingStroke({required this.color, required this.strokeWidth});
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawingStroke> strokes;
  final _DrawingStroke? currentStroke;

  _DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  void _paintStroke(Canvas canvas, _DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
