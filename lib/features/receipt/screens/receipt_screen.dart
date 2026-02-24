import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../library/providers/library_providers.dart';
import '../../../data/models/user_book_model.dart';
import 'dart:math';

class ReceiptScreen extends ConsumerWidget {
  final String period; // 'month', 'year', 'all'

  const ReceiptScreen({
    super.key,
    required this.period,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider);

    return booksAsync.when(
      data: (allBooks) {
        // Filter books based on period and status 'read'
        final now = DateTime.now();
        final readBooks = allBooks.where((b) {
          if (b.status != 'read' || b.finishedAt == null) return false;
          final date = b.finishedAt!;
          if (period == 'month') {
            return date.year == now.year && date.month == now.month;
          } else if (period == 'year') {
            return date.year == now.year;
          }
          return true; // all
        }).toList();

        // Sort by finished date descending
        readBooks.sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));

        return Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFD), // Paper white
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zig-zag Top
              SizedBox(
                height: 10,
                child: CustomPaint(
                  painter: ZigZagPainter(color: const Color(0xFFFDFDFD)),
                  size: const Size(double.infinity, 10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.bookmark_border, size: 32, color: Colors.black),
                          const SizedBox(height: 8),
                          Text(
                            'FLORENCE READING SHOP',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontFamily: 'Courier', // Monospace if available
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontFamily: 'Courier',
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.black, thickness: 1, height: 1),
                          const Divider(color: Colors.black, thickness: 1, height: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Item List
                    if (readBooks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No books read in this period.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Courier'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: readBooks.length,
                        itemBuilder: (context, index) {
                          final book = readBooks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    book.book.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '1', // Qty
                                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black, thickness: 1, height: 1),
                    const SizedBox(height: 8),
                    // Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL QTY',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${readBooks.length}',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Barcode Placeholder
                    Container(
                      height: 40,
                      color: Colors.black, // Placeholder for barcode
                      child: Center(
                         child: Text(
                           '|| ||| || ||||| || |||',
                           style: TextStyle(color: Colors.white, letterSpacing: 4),
                         ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'THANK YOU FOR READING',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Zig-zag Bottom
              Transform.rotate(
                angle: pi,
                child: SizedBox(
                  height: 10,
                  child: CustomPaint(
                    painter: ZigZagPainter(color: const Color(0xFFFDFDFD)),
                    size: const Size(double.infinity, 10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: FlorenceLoader()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class ZigZagPainter extends CustomPainter {
  final Color color;

  ZigZagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    
    // Zig-zag pattern
    double x = 0;
    double y = 0;
    double step = 10;
    
    path.moveTo(0, 0);
    while (x < size.width) {
      path.lineTo(x + step / 2, size.height);
      path.lineTo(x + step, 0);
      x += step;
    }
    
    path.lineTo(size.width, size.height * 2); // Extend down to cover any gaps if needed
    path.lineTo(0, size.height * 2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
