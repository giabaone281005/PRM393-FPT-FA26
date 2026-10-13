import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/auth_repository.dart';
import '../main/main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _errorMsg = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng điền đầy đủ thông tin');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    final result = _isLogin
        ? await AuthRepository.signIn(email: email, password: pass)
        : await AuthRepository.signUp(email: email, password: pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      setState(() => _errorMsg = result.error ?? 'Có lỗi xảy ra');
    }
  }

  // Demo: skip auth and go straight to app
  void _skipAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF4A7FBD), Color(0xFF2DD4BF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Mascot + Logo
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🦉', style: TextStyle(fontSize: 52)),
                      ),
                    ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(
                      'MathLingo',
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Học Toán Vui – Chinh Phục Từng Ngày 🚀',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),

                const SizedBox(height: 40),

                // Card Auth
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab toggle
                      Row(
                        children: [
                          Expanded(
                            child: _buildTab('Đăng Nhập', _isLogin, () {
                              setState(() {
                                _isLogin = true;
                                _errorMsg = '';
                              });
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTab('Đăng Ký', !_isLogin, () {
                              setState(() {
                                _isLogin = false;
                                _errorMsg = '';
                              });
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Email field
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email phụ huynh',
                        icon: Icons.email_rounded,
                        keyboard: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu (ít nhất 6 ký tự)',
                          prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceSubtle,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),

                      // Error message
                      if (_errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.accentRed.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.accentRed, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg,
                                  style: const TextStyle(color: AppColors.accentRed, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withAlpha(100),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isLogin ? 'ĐĂNG NHẬP' : 'TẠO TÀI KHOẢN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),

                      const SizedBox(height: 12),

                      // Quick 1-click Demo Account button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          setState(() {
                            _emailCtrl.text = 'phuhuynh@mathlingo.vn';
                            _passCtrl.text = 'MathLingo@2026';
                            _isLogin = true;
                          });
                          _submit();
                        },
                        icon: const Icon(Icons.flash_on_rounded, color: AppColors.accentGold, size: 20),
                        label: const Text(
                          'Đăng nhập tài khoản Test (Phụ huynh Demo)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Demo mode skip button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _skipAuth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Dùng thử nhanh không cần tài khoản',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(),

                const SizedBox(height: 24),

                // Footer
                Text(
                  'MathLingo tuân thủ COPPA & an toàn cho trẻ em 🛡️',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withAlpha(150),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surfaceSubtle,
      ),
    );
  }
}
