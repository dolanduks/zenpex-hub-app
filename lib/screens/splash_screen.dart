import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'lock_screen.dart';
import 'login_screen.dart';

/// Tela de abertura do Zenpex Hub. Continua o splash nativo (mesmo fundo
/// marinho) e, no futuro, é onde entra a trava de acesso (login + biometria).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _symbolFade;
  late final Animation<double> _symbolScale;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _symbolFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _symbolScale = Tween(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _c.forward();
    _goHome();
  }

  Future<void> _goHome() async {
    await Future.delayed(const Duration(milliseconds: 1750));
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!mounted) return;
    // Prévia: vai direto à home. Com sessão: trava biométrica. Sem: login.
    final Widget next = AppConfig.devPreview
        ? const HomeScreen()
        : (loggedIn ? const LockScreen() : const LoginScreen());
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenpexColors.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ZenpexColors.navy, Color(0xFF001A3D)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _symbolFade,
                child: ScaleTransition(
                  scale: _symbolScale,
                  child: SvgPicture.asset(
                    'assets/logo/simbolo_branco.svg',
                    height: 104,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _textFade,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'PPMori',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: ZenpexColors.offWhite,
                      letterSpacing: 0.3,
                    ),
                    children: [
                      TextSpan(text: 'Zenpex '),
                      TextSpan(
                        text: 'Hub',
                        style: TextStyle(color: ZenpexColors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
