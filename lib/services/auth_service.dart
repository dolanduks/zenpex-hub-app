import 'package:msal_auth/msal_auth.dart';

import '../config/app_config.dart';

/// Login Microsoft (Entra ID) nativo via MSAL (broker / Custom Tab).
///
/// Usa o SDK oficial da Microsoft (msal_auth). O MSAL cuida do fluxo de
/// autorização, do cache de tokens e do refresh silencioso — por isso não
/// guardamos tokens manualmente. O backend valida o access token do Graph.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SingleAccountPca? _pca;
  String? _cachedToken;

  Future<SingleAccountPca> _client() async {
    return _pca ??= await SingleAccountPca.create(
      clientId: AppConfig.clientId,
      androidConfig: AndroidConfig(
        configFilePath: 'assets/msal_config.json',
        redirectUri: AppConfig.redirectUrl,
      ),
    );
  }

  /// Já existe conta logada? Tenta um token silencioso; se der, está logado.
  Future<bool> isLoggedIn() async {
    if (AppConfig.devPreview) return true;
    try {
      final pca = await _client();
      final result = await pca.acquireTokenSilent(scopes: AppConfig.scopes);
      _cachedToken = result.accessToken;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Login interativo (abre o broker/Custom Tab da Microsoft).
  Future<void> login() async {
    final pca = await _client();
    final result = await pca.acquireToken(
      scopes: AppConfig.scopes,
      prompt: Prompt.whenRequired,
    );
    _cachedToken = result.accessToken;
  }

  /// Access token válido para o Graph; renova em silêncio quando necessário.
  Future<String?> validAccessToken() async {
    if (AppConfig.devPreview) return 'preview';
    try {
      final pca = await _client();
      final result = await pca.acquireTokenSilent(scopes: AppConfig.scopes);
      _cachedToken = result.accessToken;
      return result.accessToken;
    } catch (_) {
      return _cachedToken;
    }
  }

  Future<void> logout() async {
    try {
      final pca = await _client();
      await pca.signOut();
    } catch (_) {}
    _cachedToken = null;
  }
}
