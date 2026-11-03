import 'package:flutter/material.dart';

import '../theme.dart';

/// Como o item abre quando tocado.
enum HubTarget {
  /// Seção do hub web (hub.zenpex.com.br) embutida no app.
  hub,

  /// Acesso externo embutido (Guacamole, Passbolt).
  access,
}

/// Um atalho da home do Zenpex Hub.
class HubModule {
  const HubModule({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.target,
    required this.path,
    this.androidPackage,
    this.native = false,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final HubTarget target;

  /// Caminho relativo no hub (target.hub) ou URL completa (target.access).
  final String path;

  /// Pacote do app Android oficial a abrir em vez da WebView (ex.: Passbolt).
  final String? androidPackage;

  /// Módulo já reescrito de forma nativa (abre tela Flutter, não WebView).
  final bool native;

  /// URL final a abrir na WebView.
  String get url => target == HubTarget.hub ? '$hubBaseUrl$path' : path;
}

/// Base pública do hub web.
const hubBaseUrl = 'https://hub.zenpex.com.br';

/// Módulos do hub, na ordem da home.
const hubModules = <HubModule>[
  HubModule(
    id: 'financeiro',
    label: 'Financeiro',
    subtitle: 'Lançamentos, DRE e relatórios',
    icon: Icons.account_balance_wallet_outlined,
    accent: ZenpexColors.blue,
    target: HubTarget.hub,
    path: '/dashboard/financeiro',
    native: true,
  ),
  HubModule(
    id: 'clientes',
    label: 'Clientes',
    subtitle: 'Cadastro e carteira',
    icon: Icons.groups_outlined,
    accent: Color(0xFF7C9BFF),
    target: HubTarget.hub,
    path: '/dashboard/clientes',
    native: true,
  ),
  HubModule(
    id: 'nfse',
    label: 'NFS-e',
    subtitle: 'Emissão de notas',
    icon: Icons.receipt_long_outlined,
    accent: Color(0xFF3CC48A),
    target: HubTarget.hub,
    path: '/dashboard/nfse',
    native: true,
  ),
  HubModule(
    id: 'chamados',
    label: 'Chamados',
    subtitle: 'Milvus — suporte',
    icon: Icons.support_agent_outlined,
    accent: Color(0xFFF2C94C),
    target: HubTarget.hub,
    path: '/dashboard/milvus',
    native: true,
  ),
  HubModule(
    id: 'projetos',
    label: 'Projetos',
    subtitle: 'Serviços, horas e documentos',
    icon: Icons.folder_special_outlined,
    accent: Color(0xFF8C7CFF),
    target: HubTarget.hub,
    path: '/dashboard/projetos',
    native: true,
  ),
  HubModule(
    id: 'licencas',
    label: 'Licenças',
    subtitle: 'Renovações e alertas',
    icon: Icons.verified_outlined,
    accent: Color(0xFFBF8CFF),
    target: HubTarget.hub,
    path: '/dashboard/licencas',
    native: true,
  ),
  HubModule(
    id: 'wol',
    label: 'Wake-on-LAN',
    subtitle: 'Ligar máquinas remotas',
    icon: Icons.power_settings_new_outlined,
    accent: Color(0xFFF2994A),
    target: HubTarget.hub,
    path: '/dashboard/wol',
    native: true,
  ),
];

/// Acessos remotos (fora do hub).
const accessModules = <HubModule>[
  HubModule(
    id: 'guacamole',
    label: 'Guacamole',
    subtitle: 'Área de trabalho remota',
    icon: Icons.desktop_windows_outlined,
    accent: ZenpexColors.lightBlue,
    target: HubTarget.access,
    path: 'https://hubble-ts.zenpex.com.br/',
  ),
  HubModule(
    id: 'passbolt',
    label: 'Passbolt',
    subtitle: 'Cofre de senhas',
    icon: Icons.vpn_key_outlined,
    accent: Color(0xFFE5484D),
    target: HubTarget.access,
    path: 'https://vault.zenpex.com.br/',
    androidPackage: 'com.passbolt.mobile.android',
  ),
];
