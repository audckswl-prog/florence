import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../widgets/shimmer_text.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.go('/login');
  }

  // --- Page Builders ---
  Widget _buildWelcomePage(double Function(double) sh, double Function(double) sw) {
    return Column(
      children: [
        Expanded(flex: 2, child: SizedBox(height: sh(1))),
        Expanded(
          flex: 4,
          child: Center(
            child: ShimmerText(
              text: 'Firenze',
              style: GoogleFonts.greatVibes(
                fontSize: sh(84),
                color: AppColors.burgundy,
                height: 1.0,
              ),
            ),
          ),
        ),
        Expanded(flex: 1, child: SizedBox(height: sh(1))),
        Expanded(
          flex: 4, // Slightly increased to give more air
          child: _buildTextSection(
              '피렌체에 오신 것을 환영합니다',
              '피렌체를 통해 편리하게 독서를 기록해 보세요.\n자랑하는 것 같아서 마음 편히 독서 경험을 공유하지 못했던 분들, 혹은 친구와 함께 독서하고 싶은 분들, 아울러 독서를 사랑하는 분들께 피렌체 를 전합니다.',
              sh: sh),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(double Function(double) sh, double Function(double) sw) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: sw(4)),
          height: sh(8),
          width: _currentPage == index ? sw(24) : sw(8),
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.burgundy
                : AppColors.burgundy.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(sh(4)),
          ),
        );
      }),
    );
  }

  Widget _buildTextSection(String title, String subtitle, {EdgeInsetsGeometry? padding, Color titleColor = AppColors.charcoal, Color subtitleColor = AppColors.grey, required double Function(double) sh}) {
    return Container(
      padding: padding ?? EdgeInsets.fromLTRB(sh(32), sh(0), sh(32), sh(8)), // Reduced top margin for better scaling
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: sh(20),
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sh(16)), // Increased spacing between title and subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: sh(14),
              height: 1.4,
              color: subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Overlay Page Builder (Pages 2-5) ---
  Widget _buildOverlayPage(String imagePath, String title, String subtitle, double Function(double) sh) {
    return Stack(
      children: [
        // 1. Background Image
        Positioned.fill(
          top: sh(20),
          child: Container(
            padding: EdgeInsets.only(bottom: sh(220)), // Increased bottom space for larger overlay
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
        // 2. Opacity Overlay at the bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ClipPath(
                clipper: _TopArcClipper(arcStart: sh(40)),
                child: Container(
                  height: sh(340), // Increased to cover bottom comprehensively
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFAF9F6).withValues(alpha: 0.0), // Top: fully transparent
                        const Color(0xFFFAF9F6).withValues(alpha: 0.0), // Keep transparent until 35%
                        const Color(0xFFFAF9F6), // Smooth transition to opaque
                        const Color(0xFFFAF9F6), // Fully opaque at bottom
                      ],
                      stops: const [0.0, 0.35, 0.7, 1.0], // Adjusted stops for smoother text coverage
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: sh(140)), // Title/Subtitle positioned on opaque part
                child: _buildTextSection(title, subtitle, sh: sh),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 1. 서재 페이지
  Widget _buildLibraryPage(double Function(double) sh, double Function(double) sw) {
    return _buildOverlayPage(
      'assets/images/onboarding/page2.png',
      '내 손안의 작은 서재',
      '읽은 책이 실제 두께에 비례하여 빼곡하게 꽂히는 나만의 책장을 만들어보세요.',
      sh,
    );
  }

  // 2. 독서 티켓 페이지
  Widget _buildTicketPage(double Function(double) sh, double Function(double) sw) {
    return _buildOverlayPage(
      'assets/images/onboarding/page3.png',
      '함께 읽고 개성을 남기다',
      '책을 친구와 함께 읽고, 개성이 담긴 독서 티켓을 받아보세요!',
      sh,
    );
  }

  // 3. 메모 페이지
  Widget _buildMemoPage(double Function(double) sh, double Function(double) sw) {
    return _buildOverlayPage(
      'assets/images/onboarding/page4.png',
      '인상적인 문장을 사진과 함께',
      '감명 깊었던 문장과 페이지는 메모탭에 정리해두세요.',
      sh,
    );
  }

  // 4. 통계 페이지
  Widget _buildGraphPage(double Function(double) sh, double Function(double) sw) {
    return _buildOverlayPage(
      'assets/images/onboarding/page5.png',
      '나의 독서 취향 발견',
      '나의 독서 취향을 확인해보세요.',
      sh,
    );
  }

  // 5. 도슨트 페이지
  Widget _buildDocentPage(double Function(double) sh, double Function(double) sw) {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: sw(120),
                  height: sw(120),
                  child: const FlorenceLoader(),
                ),
                SizedBox(height: sh(32)),
                Text(
                  '피렌체의 도슨트가\n당신을 위한 이야기를 고르고 있습니다...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: sh(16),
                    height: 1.8,
                    color: AppColors.charcoal.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildTextSection(
              '나만의 전담 AI 도슨트',
              '피렌체 도슨트가 책의 시대적 배경과 작가에 대한 비하인드 설명을 심도 있게 제공합니다.',
              padding: EdgeInsets.fromLTRB(sh(32), sh(8), sh(32), sh(24)),
              sh: sh),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    // Scale helpers based on iPhone 15 Pro (393 x 852)
    double sh(double px) => screenHeight * (px / 852);
    double sw(double px) => screenWidth * (px / 393);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Background Content (PageView)
            Positioned.fill(
              top: sh(20), // Top padding for whole PageView
              child: PageView( // Now full screen bottom for seamless overlay
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                   _buildWelcomePage(sh, sw),
                   _buildLibraryPage(sh, sw),
                   _buildTicketPage(sh, sw),
                   _buildMemoPage(sh, sw),
                   _buildGraphPage(sh, sw),
                   _buildDocentPage(sh, sw),
                ],
              ),
            ),
            // 2. Global Page Indicator & Action Button
            Positioned(
              left: sw(24),
              right: sw(24),
              bottom: sh(max(8, MediaQuery.of(context).padding.bottom + (_currentPage == 5 ? 8 : 40))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPageIndicator(sh, sw),
                  if (_currentPage == 5) ...[
                    SizedBox(height: sh(16)),
                    SizedBox(
                      width: double.infinity,
                      height: sh(56),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.burgundy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sh(16)),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _finishOnboarding,
                        child: Text(
                          '피렌체 시작하기',
                          style: TextStyle(
                            fontSize: sh(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Top Arc Clipper for Blur Overlay ---
class _TopArcClipper extends CustomClipper<Path> {
  final double arcStart;

  _TopArcClipper({required this.arcStart});

  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, arcStart); // Proportional arc start
    path.quadraticBezierTo(size.width / 2, 0, size.width, arcStart); 
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}


