import '../config/app_config.dart';
import '../services/api_client.dart';
import 'license.dart';

class LicensesRepository {
  Future<List<License>> list() async {
    if (AppConfig.devPreview) return _sample;
    final data = await ApiClient.instance.get('/api/licenses') as List<dynamic>;
    return data.map((e) => License.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Categorias de licença: [{id, nome}].
  Future<List<Map<String, dynamic>>> categorias() async {
    if (AppConfig.devPreview) {
      return [
        {'id': 1, 'nome': 'Antivírus'},
        {'id': 2, 'nome': 'Microsoft 365'},
        {'id': 3, 'nome': 'Firewall'},
      ];
    }
    final data =
        await ApiClient.instance.get('/api/licenses/categorias') as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> create(Map<String, dynamic> payload) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.post('/api/licenses', payload);
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.put('/api/licenses/$id', payload);
  }

  Future<void> renew(int id, String dataVencimento) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance
        .put('/api/licenses/$id/renovar', {'data_vencimento': dataVencimento});
  }

  Future<void> remove(int id) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.delete('/api/licenses/$id');
  }

  static List<License> get _sample => [
        License(
          id: 1,
          nomeProduto: 'Bitdefender GravityZone',
          tipo: 'CLIENTE',
          status: 'ATIVA',
          diasParaVencimento: 12,
          dataVencimento: DateTime.now().add(const Duration(days: 12)),
          customerNome: 'Serra Diesel',
          categoryNome: 'Antivírus',
          modelo: '50 endpoints',
        ),
        License(
          id: 2,
          nomeProduto: 'Microsoft 365 Business',
          tipo: 'CLIENTE',
          status: 'ATIVA',
          diasParaVencimento: 120,
          dataVencimento: DateTime.now().add(const Duration(days: 120)),
          customerNome: 'Casa Fagundes',
          categoryNome: 'Microsoft 365',
        ),
        License(
          id: 3,
          nomeProduto: 'Sophos Firewall XGS',
          tipo: 'INTERNO',
          status: 'ATIVA',
          diasParaVencimento: -3,
          dataVencimento: DateTime.now().subtract(const Duration(days: 3)),
          categoryNome: 'Firewall',
        ),
      ];
}
