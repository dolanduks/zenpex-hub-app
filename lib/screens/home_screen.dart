import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/hub_modules.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'chamados_screen.dart';
import 'clientes_screen.dart';
import 'financeiro_screen.dart';
import 'licencas_screen.dart';
import 'nfse_screen.dart';
import 'projetos_screen.dart';
import 'login_screen.dart';
import 'web_screen.dart';
import 'wol_screen.dart';

void _openModule(BuildContext context, HubModule m) {
  // Módulos já nativos abrem a tela Flutter correspondente.
  if (m.native) {
    final Widget? screen = switch (m.id) {
      'financeiro' => const FinanceiroScreen(),
      'nfse' => const NfseScreen(),
      'clientes' => const ClientesScreen(),
      'licencas' => const LicencasScreen(),
      'chamados' => const ChamadosScreen(),
      'projetos' => const ProjetosScreen(),
      'wol' => const WolScreen(),
      _ => null,
    };
    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      return;
    }
  }
  // Passbolt e afins abrem o app oficial (a WebView não serve por causa da
  // criptografia ponta a ponta); cai na Play Store se não estiver instalado.
  final pkg = m.androidPackage;
  if (pkg != null) {
    LaunchApp.openApp(androidPackageName: pkg, openStore: true);
    return;
  }
  // Demais módulos ainda abrem o hub em WebView (migração em andamento).
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => WebScreen(title: m.label, url: m.url),
    ),
  );
}

Future<void> _logout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ZenpexColors.surfaceHigh,
      title: const Text('Sair'),
      content: const Text('Encerrar a sessão neste aparelho?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ZenpexColors.blue),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sair'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await AuthService.instance.logout();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(greeting: _greeting()),
              const SizedBox(height: 8),
              const _SectionTitle('Gestão'),
              _ModuleGrid(modules: hubModules),
              const SizedBox(height: 20),
              const _SectionTitle('Acessos remotos'),
              _AccessList(modules: accessModules),
              const SizedBox(height: 28),
              const _Footer(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ZenpexColors.navy, ZenpexColors.black],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/logo/simbolo_branco.svg', height: 30),
              const SizedBox(width: 12),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'PPMori',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ZenpexColors.offWhite,
                    letterSpacing: 0.2,
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
              const Spacer(),
              GestureDetector(
                onTap: () => _logout(context),
                child: const _Avatar(initials: 'MS'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '$greeting, Marco',
            style: const TextStyle(
              fontSize: 15,
              color: ZenpexColors.lightBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O que você quer acessar?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: ZenpexColors.offWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ZenpexColors.blue.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: ZenpexColors.blue.withValues(alpha: 0.6)),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: monoFamily,
          fontFamilyFallback: monoFallback,
          fontWeight: FontWeight.w700,
          color: ZenpexColors.offWhite,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: monoFamily,
          fontFamilyFallback: monoFallback,
          fontSize: 12,
          letterSpacing: 1.6,
          color: ZenpexColors.textMuted,
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.modules});

  final List<HubModule> modules;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: modules.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (context, i) => _ModuleCard(module: modules[i]),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final HubModule module;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZenpexColors.surfaceHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openModule(context, module),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ZenpexColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: module.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(module.icon, color: module.accent, size: 24),
              ),
              const Spacer(),
              Text(
                module.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ZenpexColors.offWhite,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                module.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: ZenpexColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessList extends StatelessWidget {
  const _AccessList({required this.modules});

  final List<HubModule> modules;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (final m in modules) ...[
            _AccessCard(module: m),
            if (m != modules.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.module});

  final HubModule module;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZenpexColors.surfaceHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openModule(context, module),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ZenpexColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: module.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(module.icon, color: module.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ZenpexColors.offWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ZenpexColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_outward,
                color: ZenpexColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 14, color: ZenpexColors.ok),
          const SizedBox(width: 6),
          Text(
            'Protegido por login Microsoft + biometria',
            style: TextStyle(
              fontSize: 12,
              color: ZenpexColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
