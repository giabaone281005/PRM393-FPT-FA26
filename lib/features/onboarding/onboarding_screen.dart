import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_typography.dart';
import '../auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      emoji: '🗺️',
      title: 'Bản Đồ Kho Báu\nToán Học',
      body: 'Mỗi bài học chỉ 3–5 phút. Chinh phục từng đảo kiến thức với lộ trình trực quan, sinh động!',
      gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    ),
    _OnboardPage(
      emoji: '🦉',
      title: 'Gia Sư AI Cú\nSocratic',
      body: 'Bé sai? Cú gợi mở từng bước – không giải hộ – giúp trẻ tự tư duy và tìm ra đáp án!',
      gradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    ),
    _OnboardPage(
      emoji: '👨‍👩‍👦',
      title: 'Phụ Huynh\nNắm Tất Cả',
      body: 'Theo dõi điểm mạnh/yếu, giới hạn thời gian học, quản lý nhiều bé trong một tài khoản.',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (ctx, i) {
              final page = _pages[i];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: page.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 40, 0, 160),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            page.emoji,
                            style: const TextStyle(fontSize: 96),
                          ).animate(key: ValueKey('emoji_$i')).scale(duration: 600.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ).animate(key: ValueKey('title_$i')).fadeIn(delay: 200.ms).slideY(begin: 0.3),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              page.body,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withAlpha(210),
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ).animate(key: ValueKey('body_$i')).fadeIn(delay: 350.ms),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withAlpha(60)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.white
                              : Colors.white.withAlpha(100),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A5F),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage < _pages.length - 1 ? 'TIẾP THEO' : 'BẮT ĐẦU NGAY',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage < _pages.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.rocket_launch_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  if (_currentPage < _pages.length - 1) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      child: Text(
                        'Bỏ qua',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String emoji;
  final String title;
  final String body;
  final List<Color> gradient;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
  });
}
