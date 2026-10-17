import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_service.dart';
import 'data/providers/app_state_provider.dart';
import 'features/main/main_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/account_screen.dart';
import 'data/repositories/auth_repository.dart';
import 'features/admin/content_management_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppStateProvider())],
      child: const MathLingoApp(),
    ),
  );
}

class MathLingoApp extends StatefulWidget {
  const MathLingoApp({super.key});

  @override
  State<MathLingoApp> createState() => _MathLingoAppState();
}

class _MathLingoAppState extends State<MathLingoApp> {
  final _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _listener;
  @override
  void initState() {
    super.initState();
    _listener = SupabaseService.client?.auth.onAuthStateChange.listen(
      (event) {
        if (AuthRepository.verificationScreenOpen) return;
        if (event.event == AuthChangeEvent.signedOut) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _navigator.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (_) => false,
              );
            }
          });
        }
        if (event.event == AuthChangeEvent.passwordRecovery) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _navigator.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const AccountScreen(recovery: true),
                ),
                (_) => false,
              );
            }
          });
        }
      },
      onError: (Object error) {
        if (AuthRepository.verificationScreenOpen) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _navigator.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AuthScreen(
                initialMessage: AuthRepository.emailError(error),
                initialNotice: false,
              ),
            ),
            (_) => false,
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _listener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return MaterialApp(
          navigatorKey: _navigator,
          title: 'MathLingo - Học Toán Vui Cùng Cú',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          home: const _SplashWrapper(),
        );
      },
    );
  }
}

class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.6, curve: Curves.easeIn),
      ),
    );
    _scale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _ctrl.forward();

    // Auto-navigate after splash directly to AuthScreen (Đăng Nhập)
    _splashTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      final state = context.read<AppStateProvider>();
      if (SupabaseService.isLoggedIn) await state.refreshFromCloud();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => !SupabaseService.isLoggedIn
              ? const AuthScreen()
              : state.isAdmin
              ? const AdminDashboardScreen()
              : state.isStaff
              ? const ContentManagementScreen()
              : const MainScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mascot
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/owl_mascot.jpg',
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text('🦉', style: TextStyle(fontSize: 58)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'MathLingo',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Học Toán Vui – Chinh Phục Từng Ngày',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(200),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
