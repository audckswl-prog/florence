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
  double _strokeWidth = 3.0;
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
    // 가로 모드 강제 적용
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 상단바/네비바 숨기기 (옵션 - 몰입감 증대)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // 세로 모드로 복구
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // 시스템 UI 복구
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // 배경을 더 어둡게 하여 캔버스 강조
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '구절을 그림으로 그려주세요 (가로)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
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
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Canvas area (Central)
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 4 / 3, // 고정 비율 캔버스
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _canvasBgColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: Container(
                        color: _canvasBgColor,
                        child: GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _currentStroke = _DrawingStroke(
                                color: _isEraser ? _canvasBgColor : _currentColor,
                                strokeWidth: _isEraser ? _strokeWidth * 3 : _strokeWidth, // 지우개는 좀 더 크게
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
              ),
            ),
          ),

          // Right: Tool bar (Vertical Stack in Landscape)
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              left: false,
              child: Column(
                children: [
                  // Undo
                  IconButton(
                    onPressed: () {
                      if (_strokes.isNotEmpty) {
                        setState(() => _strokes.removeLast());
                      }
                    },
                    icon: const Icon(Icons.undo, color: Colors.white),
                  ),
                  const Spacer(),
                  // Eraser
                  GestureDetector(
                    onTap: () => setState(() => _isEraser = !_isEraser),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isEraser ? AppColors.burgundy : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_fix_normal, // Eraser icon
                        color: _isEraser ? Colors.white : Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Color palette (Vertical)
                  ..._palette.map((color) {
                    final isSelected = !_isEraser && _currentColor == color;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _currentColor = color;
                        _isEraser = false;
                      }),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        width: isSelected ? 32 : 24,
                        height: isSelected ? 32 : 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white30,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const Spacer(),
                  // Clear
                  IconButton(
                    onPressed: () => setState(() => _strokes.clear()),
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
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
