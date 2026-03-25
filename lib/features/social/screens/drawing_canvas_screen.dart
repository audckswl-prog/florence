import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  final GlobalKey _canvasKey = GlobalKey();

  static const List<Color> _palette = [
    AppColors.charcoal, // Graphite / Black Ink
    AppColors.burgundy, // Signature Firenze Wine
    Color(0xFF2B4D6A),  // Vintage Navy Ink
    Color(0xFF4A5C46),  // Classic Olive Green
    Color(0xFF987B5B),  // Sepia / Camel Brown
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '구절을 그림으로 표현해주세요',
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
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAE1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: Container(
                    color: const Color(0xFFF0EAE1),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _currentStroke = _DrawingStroke(
                            color: _currentColor,
                            strokeWidth: _strokeWidth,
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

          // Tool bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color palette
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _palette.map((color) {
                      final isSelected = _currentColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _currentColor = color),
                        child: Container(
                          width: isSelected ? 36 : 28,
                          height: isSelected ? 36 : 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Stroke width slider + undo/clear
                  Row(
                    children: [
                      const Icon(Icons.brush, color: Colors.white, size: 18),
                      Expanded(
                        child: Slider(
                          value: _strokeWidth,
                          min: 1.0,
                          max: 12.0,
                          activeColor: AppColors.burgundy,
                          inactiveColor: Colors.white24,
                          onChanged: (val) =>
                              setState(() => _strokeWidth = val),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_strokes.isNotEmpty) {
                            setState(() => _strokes.removeLast());
                          }
                        },
                        icon: const Icon(Icons.undo, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _strokes.clear());
                        },
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                    ],
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
