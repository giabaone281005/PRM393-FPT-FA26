import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../main/main_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'widgets/mascot_owl_3d.dart';
import 'widgets/otp_verification_dialog.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Mode: 1 = Login, 2 = Sign Up
  int _screenMode = 1;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  MascotState _mascotState = MascotState.idle;
  String _mascotSpeech = 'Chào bạn! Mình là bạn Cú Toán Học ✨';
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_handleFocusChange);
    _emailFocus.addListener(_handleFocusChange);
    _passFocus.addListener(_handleFocusChange);
    _confirmPassFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      if (_passFocus.hasFocus || _confirmPassFocus.hasFocus) {
        _mascotState = MascotState.typingPassword;
        _mascotSpeech = 'Suỵt! Mình bịt mắt lại giữ bí mật mật khẩu nhé 🙈';
      } else if (_phoneFocus.hasFocus) {
        _mascotState = MascotState.typingEmail;
        _mascotSpeech = 'Nhập số điện thoại để liên hệ xác thực nha! 📱';
      } else if (_emailFocus.hasFocus) {
        _mascotState = MascotState.typingEmail;
        _mascotSpeech = 'Nhập đúng địa chỉ email nhận OTP nha! ✉️';
      } else {
        _mascotState = MascotState.idle;
        _mascotSpeech = 'Chạm vào mình để nhận lời chúc nào! ✨';
      }
    });
  }

  @override
  void dispose() {
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _onMascotTap() {
    setState(() {
      _mascotState = MascotState.tapped;
      _mascotSpeech = 'MathLingo chúc bạn và bé học thật vui! 🚀';
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _mascotState == MascotState.tapped) {
        setState(() {
          _mascotState = MascotState.idle;
          _mascotSpeech = 'Sẵn sàng học toán cùng mình chưa? 🎉';
        });
      }
    });
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final phone = _phoneCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() {
        _errorMsg = 'Vui lòng điền email và mật khẩu';
        _mascotSpeech = 'Ơ, bạn chưa điền đủ thông tin kìa! 🤔';
      });
      return;
    }

    if (_screenMode == 2) {
      if (phone.isEmpty) {
        setState(() {
          _errorMsg = 'Vui lòng nhập số điện thoại phụ huynh';
          _mascotSpeech = 'Đừng quên nhập số điện thoại để bảo mật nhé! 📱';
        });
        return;
      }

      if (pass != _confirmPassCtrl.text) {
        setState(() {
          _errorMsg = 'Mật khẩu xác nhận không khớp';
          _mascotSpeech = 'Mật khẩu 2 lần chưa trùng nhau rồi! ✍️';
        });
        return;
      }

      // Quy trình OTP: Phát sinh mã ngẫu nhiên gửi về email và mở dialog xác thực
      final randomOtp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => OtpVerificationDialog(
          email: email,
          generatedOtp: randomOtp,
          onVerified: () => _executeSignUp(email, pass, phone),
        ),
      );
      return;
    }

    // Đăng nhập
    setState(() {
      _loading = true;
      _errorMsg = '';
      _mascotState = MascotState.celebrate;
      _mascotSpeech = 'Đang kiểm tra tài khoản, đợi mình tí nhé... ⏳';
    });

    final result = await AuthRepository.signIn(email: email, password: pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      setState(() {
        _mascotSpeech = 'Hoan hô! Đăng nhập thành công! 🌟';
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      // Kiểm tra quyền Admin để phân luồng UI riêng
      final isEmailAdmin = email.trim().toLowerCase() == 'admin.moi@mathlingo.vn' ||
          email.trim().toLowerCase() == 'admin@mathlingo.vn';
      final isAdminRole = await SubscriptionRepository.checkIfAdmin();
      if (!mounted) return;

      if (isEmailAdmin || isAdminRole) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      setState(() {
        _errorMsg = result.error ?? 'Có lỗi xảy ra';
        _mascotState = MascotState.idle;
        _mascotSpeech = 'Đăng nhập chưa được rồi, thử lại nhé! 💡';
      });
    }
  }

  Future<void> _executeSignUp(String email, String pass, String phone) async {
    setState(() {
      _loading = true;
      _errorMsg = '';
      _mascotState = MascotState.celebrate;
      _mascotSpeech = 'Xác thực OTP thành công! Đang thiết lập tài khoản... 🚀';
    });

    final result = await AuthRepository.signUp(email: email, password: pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Chúc mừng bạn đã đăng ký tài khoản MathLingo thành công! (SĐT: $phone)'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      setState(() {
        _mascotSpeech = 'Tài khoản đã sẵn sàng! Chào mừng bạn và bé! 🌟';
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      setState(() {
        _errorMsg = result.error ?? 'Đăng ký không thành công';
        _mascotState = MascotState.idle;
        _mascotSpeech = 'Có chút sự cố khi tạo tài khoản, thử lại nha! 💡';
      });
    }
  }

  void _skipAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _fillDemoAccount() {
    _emailCtrl.text = 'phuhuynh@mathlingo.vn';
    _passCtrl.text = '123456';
    setState(() {
      _errorMsg = '';
      _mascotSpeech = 'Đã điền tài khoản Phụ huynh mẫu! Bấm Đăng Nhập nào ⚡';
    });
  }

  void _fillAdminAccount() {
    _emailCtrl.text = 'admin.moi@mathlingo.vn';
    _passCtrl.text = '123456';
    setState(() {
      _errorMsg = '';
      _mascotSpeech = 'Đã điền tài khoản Quản trị Admin! Bấm Đăng Nhập nào 👑';
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final isDark = appState.isDarkMode;

    // Harmonious Colors according to UI/UX Pro Max Claymorphism Guidelines
    final headerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFF0284C7); // MathLingo Ocean Blue
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryAccent = const Color(0xFFF97316); // MathLingo Orange
    final textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: headerBg,
      body: Stack(
        children: [
          // ================= 1. TOP HERO HEADER & MASCOT 3D ĐỨNG GIỮA TRANG =================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenH * 0.44,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // Top App Bar: Brand Pill & Dark Theme Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // MathLingo brand badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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

                        // Modern Theme Switcher Pill
                        GestureDetector(
                          onTap: () => appState.toggleTheme(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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

                    const Spacer(),

                    // Speech Bubble positioned centered above mascot
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        key: ValueKey<String>(_mascotSpeech),
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _mascotSpeech,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),

                    // MASCOT CON CÚ 3D ĐỨNG CHÍNH GIỮA TRANG
                    Center(
                      child: MascotOwl3D(
                        size: 96,
                        state: _mascotState,
                        onTap: _onMascotTap,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ================= 2. INTERACTIVE DRAGGABLE SHEET (VUỐT LÊN / XUỐNG) =================
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.50,
            maxChildSize: 0.94,
            snap: true,
            snapSizes: const [0.58, 0.94],
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
                      color: Colors.black.withValues(alpha: 0.18),
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
                        margin: const EdgeInsets.only(bottom: 18),
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
                              _mascotSpeech = _screenMode == 1
                                  ? 'Chào mừng bạn quay lại MathLingo! 🌟'
                                  : 'Tuyệt vời! Cùng tạo tài khoản mới nào 🎉';
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

                    const SizedBox(height: 22),

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
                      _buildModernInput(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        placeholder: 'Số điện thoại phụ huynh',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
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
                      focusNode: _emailFocus,
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
                      focusNode: _passFocus,
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
                        focusNode: _confirmPassFocus,
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
                        // Nút Phụ Huynh Demo
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
                                'Demo Mẹ',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nút Admin Demo
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _fillAdminAccount,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8E1),
                              ),
                              child: Text(
                                '👑 Admin',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                  fontSize: 12,
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
    FocusNode? focusNode,
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
        focusNode: focusNode,
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
