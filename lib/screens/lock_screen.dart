import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';

import '../theme.dart';
import 'home_screen.dart';

/// Trava de acesso do Zenpex Hub: pede biometria (ou PIN do aparelho) antes de
/// liberar a home. É o MFA de acesso principal no dispositivo.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

enum _LockState { idle, authenticating, failed }

class _LockScreenState extends State<LockScreen> {
  final _localAuth = LocalAuthentication();
  _LockState _state = _LockState.idle;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _unlock() async {
    if (_state == _LockState.authenticating) return;
    setState(() => _state = _LockState.authenticating);
    bool ok = false;
    try {
      ok = await _localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para acessar o Zenpex Hub',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      setState(() => _state = _LockState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authenticating = _state == _LockState.authenticating;
    final failed = _state == _LockState.failed;

    return Scaffold(
      backgroundColor: ZenpexColors.navy,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ZenpexColors.navy, Color(0xFF001A3D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                SvgPicture.asset('assets/logo/simbolo_branco.svg', height: 72),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'PPMori',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ZenpexColors.offWhite,
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
                const SizedBox(height: 10),
                Text(
                  failed
                      ? 'Não foi possível confirmar. Tente de novo.'
                      : 'Acesso protegido. Desbloqueie para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: failed
                        ? const Color(0xFFEB6B4D)
                        : ZenpexColors.lightBlue,
                  ),
                ),
                const Spacer(flex: 4),
                _UnlockButton(
                  busy: authenticating,
                  failed: failed,
                  onTap: _unlock,
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 14, color: ZenpexColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Conta Microsoft + biometria',
                      style: TextStyle(
                        fontSize: 12,
                        color: ZenpexColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({
    required this.busy,
    required this.failed,
    required this.onTap,
  });

  final bool busy;
  final bool failed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: busy ? null : onTap,
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ZenpexColors.blue.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: ZenpexColors.blue.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ZenpexColors.lightBlue,
                    ),
                  )
                : const Icon(
                    Icons.fingerprint,
                    size: 42,
                    color: ZenpexColors.offWhite,
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          busy
              ? 'Verificando…'
              : (failed ? 'Tentar novamente' : 'Toque para desbloquear'),
          style: const TextStyle(
            fontSize: 14,
            color: ZenpexColors.offWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
