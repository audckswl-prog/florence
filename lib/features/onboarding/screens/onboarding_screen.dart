import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../widgets/writing_text.dart';
import 'dart:ui';

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
  Widget _buildWelcomePage() {
    return Column(
      children: [
        const Expanded(flex: 2, child: SizedBox()),
        Expanded(
          flex: 4,
          child: Center(
            child: WritingText(
              text: 'Firenze',
              style: GoogleFonts.greatVibes(
                fontSize: 84,
                color: AppColors.burgundy,
                height: 1.0,
              ),
            ),
          ),
        ),
        const Expanded(flex: 1, child: SizedBox()),
        Expanded(
          flex: 3,
          child: _buildTextSection(
              '피렌체에 오신 것을 환영합니다',
              '피렌체를 통해 편리하게 독서를 기록해 보세요.\n자랑하는 것 같아서 마음 편히 독서 경험을 공유하지 못했던 분들, 혹은 친구와 함께 독서하고 싶은 분들, 아울러 독서를 사랑하는 분들께 피렌체를 전합니다.'),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.burgundy
                : AppColors.burgundy.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildTextSection(String title, String subtitle, {EdgeInsetsGeometry? padding, Color titleColor = AppColors.charcoal, Color subtitleColor = AppColors.grey}) {
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(32, 8, 32, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
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
  Widget _buildOverlayPage(String imagePath, String title, String subtitle) {
    return Stack(
      children: [
        // 1. Background Image (Keep current size but allow overflow/placement)
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.only(bottom: 120), // Leave some space for text background
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
        // 2. Blurred Arc Overlay at the bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ClipPath(
                clipper: _TopArcClipper(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFFAF9F6).withValues(alpha: 0.7),
                          const Color(0xFFFAF9F6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildTextSection(title, subtitle),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 1. 서재 페이지
  Widget _buildLibraryPage() {
    return _buildOverlayPage(
      'assets/images/onboarding/page2.png',
      '내 손안의 작은 서재',
      '읽은 책이 실제 두께에 비례하여 빼곡하게 꽂히는 나만의 책장을 만들어보세요.',
    );
  }

  // 2. 독서 티켓 페이지
  Widget _buildTicketPage() {
    return _buildOverlayPage(
      'assets/images/onboarding/page3.png',
      '함께 읽고 개성을 남기다',
      '책을 친구와 함께 읽고, 개성이 담긴 독서 티켓을 받아보세요!',
    );
  }

  // 3. 메모 페이지
  Widget _buildMemoPage() {
    return _buildOverlayPage(
      'assets/images/onboarding/page4.png',
      '인상적인 문장을 사진과 함께',
      '감명 깊었던 문장과 페이지는 메모탭에 정리해두세요.',
    );
  }

  // 4. 통계 페이지
  Widget _buildGraphPage() {
    return _buildOverlayPage(
      'assets/images/onboarding/page5.png',
      '나의 독서 취향 발견',
      '나의 독서 취향을 확인해보세요.',
    );
  }

  // 5. 도슨트 페이지
  Widget _buildDocentPage() {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 120,
                  height: 120,
                  child: FlorenceLoader(),
                ),
                const SizedBox(height: 32),
                Text(
                  '피렌체의 도슨트가\n당신을 위한 이야기를 고르고 있습니다...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
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
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(),
                  _buildLibraryPage(),
                  _buildTicketPage(),
                  _buildMemoPage(),
                  _buildGraphPage(),
                  _buildDocentPage(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, max(8, MediaQuery.of(context).padding.bottom + 8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPageIndicator(),
                  if (_currentPage == 5) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.burgundy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _finishOnboarding,
                        child: const Text(
                          '피렌체 시작하기',
                          style: TextStyle(
                            fontSize: 18,
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
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 40); // Start slightly down
    path.quadraticBezierTo(size.width / 2, 0, size.width, 40); // Convex arc
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}


