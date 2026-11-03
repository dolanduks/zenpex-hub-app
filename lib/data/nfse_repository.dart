import '../config/app_config.dart';
import '../services/api_client.dart';
import 'nfse.dart';

class NfseRepository {
  Future<List<Nfse>> list({String? status}) async {
    if (AppConfig.devPreview) return _sample;
    final qs = status != null ? '?status=$status' : '';
    final data = await ApiClient.instance.get('/api/nfse$qs') as List<dynamic>;
    return data.map((e) => Nfse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Nfse> emitir(int id) async {
    if (AppConfig.devPreview) return _sample.firstWhere((n) => n.id == id);
    await ApiClient.instance.post('/api/nfse/emitir', {'ids': [id]});
    final data =
        await ApiClient.instance.get('/api/nfse/$id') as Map<String, dynamic>;
    return Nfse.fromJson(data);
  }

  Future<void> cancelar(int id, int codigoMotivo, String motivo) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.post(
      '/api/nfse/$id/cancelar',
      {'codigo_motivo': codigoMotivo, 'motivo': motivo},
    );
  }

  Future<void> reenviarEmail(int id) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.post('/api/nfse/$id/reenviar-email', {});
  }

  Future<void> descartar(int id) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.delete('/api/nfse/$id');
  }

  static List<Nfse> get _sample => [
        Nfse(
          id: 1,
          status: 'EMITIDA',
          descricao: 'Suporte técnico mensal — outubro',
          valorServico: 4500,
          competencia: DateTime(2026, 10, 1),
          clienteNome: 'Serra Diesel',
          numeroNfse: '2026/000148',
          emitidaEm: DateTime(2026, 10, 5),
          emailEnviadoEm: DateTime(2026, 10, 5),
          emailDestinatarios: 'financeiro@serradiesel.com.br',
          temPdf: true,
        ),
        Nfse(
          id: 2,
          status: 'RASCUNHO',
          descricao: 'Consultoria de rede',
          valorServico: 1800,
          competencia: DateTime(2026, 10, 1),
          clienteNome: 'Casa Fagundes',
        ),
        Nfse(
          id: 3,
          status: 'REJEITADA',
          descricao: 'Instalação de firewall',
          valorServico: 3200,
          competencia: DateTime(2026, 10, 1),
          clienteNome: 'Kinix',
          mensagemErro:
              'Código de serviço (cTribNac) inválido para o município.',
        ),
      ];
}
