/// Configuração do app nativo: Entra ID (login Microsoft) e base da API do hub.
abstract final class AppConfig {
  static const tenantId = '61b00298-cf8d-433c-a663-503bc550a180';
  static const clientId = 'd137811c-2e2e-4997-a5d8-3f8859f3c1ef';
  // Redirect do MSAL (broker). Formato oficial msauth://<pacote>/<hash-url-encoded>,
  // já registrado no Entra como URI de cliente público.
  static const redirectUrl =
      'msauth://br.com.zenpex.zenpex_hub/Teo9%2Fy0MVJEtRhgChRgwDl92ie0%3D';

  /// Escopos de recurso. O MSAL adiciona openid/profile/offline_access
  /// automaticamente (e rejeita se forem passados aqui). O backend valida o
  /// token chamando o Graph /me, então basta o User.Read.
  static const scopes = <String>[
    'https://graph.microsoft.com/User.Read',
  ];

  /// Base da API do hub exposta para o app.
  static const apiBase = 'https://hub.zenpex.com.br/mobile-api';

  /// Modo de prévia (dados de exemplo, sem login) — só para captura de telas.
  /// Sempre false em release/distribuição.
  static const devPreview = false;
}
