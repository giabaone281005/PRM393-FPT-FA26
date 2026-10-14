import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../main/main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Mode: 0 = Hero/Welcome, 1 = Login, 2 = Sign Up
  int _screenMode = 1; // Default directly into Login sheet for convenience
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _errorMsg = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng điền email và mật khẩu');
      return;
    }

    if (_screenMode == 2 && pass != _confirmPassCtrl.text) {
      setState(() => _errorMsg = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    final result = _screenMode == 1
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

  void _skipAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _fillDemoAccount() {
    _emailCtrl.text = 'parent@mathlingo.com';
    _passCtrl.text = '123456';
    setState(() => _errorMsg = '');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final isDark = appState.isDarkMode;

    // Harmonious Colors according to AppColors & Theme
    final headerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFF0284C7); // MathLingo Ocean Blue
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryAccent = const Color(0xFFF97316); // MathLingo Orange
    final textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: headerBg,
      body: Stack(
        children: [
          // 1. TOP HEADER & HERO SECTION
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Theme Toggle & Skip/Guest
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App Brand badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MATHLINGO',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action buttons
                        Row(
                          children: [
                            // Dark/Light toggle button
                            GestureDetector(
                              onTap: () => appState.toggleTheme(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isDark ? 'Sáng' : 'Tối',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Catchy Headline
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_screenMode),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _screenMode == 1
                                  ? 'Đăng nhập để theo dõi\nhành trình học của bé.'
                                  : 'Tạo tài khoản & bắt đầu\ntrải nghiệm MathLingo',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Học toán vui qua trò chơi cùng MathLingo',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // 2. INTERACTIVE BOTTOM SHEET (VUỐT LÊN / VUỐT XUỐNG)
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const [0.65, 0.95],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  children: [
                    // Pull Handle Indicator
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Sheet Title & Switcher Mode link
                    Center(
                      child: Text(
                        _screenMode == 1 ? 'Đăng Nhập' : 'Tạo Tài Khoản',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _screenMode == 1 ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _screenMode = _screenMode == 1 ? 2 : 1;
                              _errorMsg = '';
                            });
                          },
                          child: Text(
                            _screenMode == 1 ? 'Đăng ký ngay' : 'Đăng nhập',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_errorMsg.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Input: Full name (Sign Up only)
                    if (_screenMode == 2) ...[
                      _buildModernInput(
                        controller: _nameCtrl,
                        placeholder: 'Họ và tên phụ huynh',
                        prefixIcon: Icons.person_outline_rounded,
                        bgColor: inputBg,
                        borderColor: borderCol,
                        textColor: textDark,
                        hintColor: textMuted,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Input: Email
                    _buildModernInput(
                      controller: _emailCtrl,
                      placeholder: 'Nhập địa chỉ email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline_rounded,
                      bgColor: inputBg,
                      borderColor: borderCol,
                      textColor: textDark,
                      hintColor: textMuted,
                    ),

                    const SizedBox(height: 14),

                    // Input: Password
                    _buildModernInput(
                      controller: _passCtrl,
                      placeholder: 'Mật khẩu',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      bgColor: inputBg,
                      borderColor: borderCol,
                      textColor: textDark,
                      hintColor: textMuted,
                    ),

                    if (_screenMode == 2) ...[
                      const SizedBox(height: 14),
                      _buildModernInput(
                        controller: _confirmPassCtrl,
                        placeholder: 'Nhập lại mật khẩu',
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: textMuted,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        bgColor: inputBg,
                        borderColor: borderCol,
                        textColor: textDark,
                        hintColor: textMuted,
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Remember Me & Forgot Password Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: primaryAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => setState(() => _rememberMe = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ghi nhớ đăng nhập',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                        if (_screenMode == 1)
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Quên mật khẩu?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryAccent,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Primary Modern Button (Clean Solid)
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                _screenMode == 1 ? 'Đăng Nhập' : 'Tạo Tài Khoản',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Or Continue With Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: borderCol)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Hoặc tiếp tục với',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: borderCol)),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Modern Flat Social / Fast Buttons
                    Row(
                      children: [
                        // Apple / Demo
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _fillDemoAccount,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderCol),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              ),
                              child: Text(
                                'Điền Demo',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Guest mode
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _skipAuth,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderCol),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              ),
                              child: Text(
                                'Vào Thử',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Safe COPPA text
                    Center(
                      child: Text(
                        'MathLingo tuân thủ COPPA và an toàn tuyệt đối cho trẻ em',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          icon: prefixIcon != null
              ? Icon(prefixIcon, size: 20, color: hintColor)
              : null,
          hintText: placeholder,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: hintColor,
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
