import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';

class GenericBookCover extends StatelessWidget {
  final Book book;
  final double? width;
  final double? height;

  const GenericBookCover({
    super.key,
    required this.book,
    this.width,
    this.height,
  });

  Color _generateColor(String key) {
    return AppColors.burgundy;
  }

  @override
  Widget build(BuildContext context) {
    final w = width ?? 80.0;
    final h = height ?? 120.0;
    final hasCover = book.coverUrl.isNotEmpty;

    // Improve Aladin cover image quality (coversum / cover150 / cover200 -> cover500)
    String highQualityCoverUrl = book.coverUrl;
    if (highQualityCoverUrl.contains('aladin.co.kr')) {
      highQualityCoverUrl = highQualityCoverUrl.replaceAll(RegExp(r'coversum|cover150|cover200'), 'cover500');
    }

    // Asymmetric border for physical book feel (spine vs open edge)
    final borderRadius = const BorderRadius.only(
      topRight: Radius.circular(6),
      bottomRight: Radius.circular(6),
      topLeft: Radius.circular(2),
      bottomLeft: Radius.circular(2),
    );

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // Soft elevation shadow (Physicality)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base Cover (Image or Fallback)
          ClipRRect(
            borderRadius: borderRadius,
            child: hasCover
                ? CachedNetworkImage(
                    imageUrl: highQualityCoverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildFallbackCover(),
                    errorWidget: (context, url, error) => _buildFallbackCover(),
                  )
                : _buildFallbackCover(),
          ),

          // 2. Spine Hinge Shadow (Left Edge)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 12, // Spine groove width
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.3), // Darker at the very edge (spine fold)
                    Colors.black.withOpacity(0.0), // Fade out
                    Colors.black.withOpacity(0.15), // Slight dip for the hinge
                    Colors.black.withOpacity(0.0), // Flat cover
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Glossy Overlay (Right side light reflection)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2), // Highlight reflection
                    Colors.white.withOpacity(0.0),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.1), // Slight shadow on bottom right
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
                // Subtle border to define the edge softly
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fallback design when image is unavailable
  Widget _buildFallbackCover() {
    final backgroundColor = _generateColor(book.isbn);
    final isDark = backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? AppColors.ivory : AppColors.burgundy;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            Color.lerp(backgroundColor, Colors.black, 0.2)!, // Slightly darker bottom-right
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 10, 10), // Left margin for spine area
        decoration: BoxDecoration(
          border: Border.all(
            color: textColor.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: Text(
          book.title,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w300, // Thinner font
            fontFamily: 'Pretendard',
            height: 1.3,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
