import '../config/app_config.dart';
import '../services/api_client.dart';
import 'projeto.dart';

class ProjetosRepository {
  Future<List<ProjetoServico>> servicos() async {
    if (AppConfig.devPreview) {
      return [
        ProjetoServico(id: 1, nome: 'Migração e-mails'),
        ProjetoServico(id: 2, nome: 'Migração SharePoint'),
        ProjetoServico(id: 3, nome: 'Ajustes Microsoft 365'),
      ];
    }
    final data = await ApiClient.instance.get('/api/projetos/servicos') as List;
    return data.map((e) => ProjetoServico.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjetoServico> criarServico(String nome) async {
    final data = await ApiClient.instance.post('/api/projetos/servicos', {'nome': nome});
    return ProjetoServico.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Projeto>> listar() async {
    if (AppConfig.devPreview) {
      return [
        Projeto(
          id: 1,
          customerId: 1,
          servicoId: 1,
          nome: 'Migração de e-mails Serra Diesel',
          descricao: 'Migração de 42 caixas do Google Workspace para o Microsoft 365.',
          valor: 8500,
          horas: 36,
          contatoCliente: 'João (TI) — joao@serradiesel.com.br',
          data: DateTime.now(),
          clienteNome: 'Serra Diesel',
          servicoNome: 'Migração e-mails',
          qtdAnexos: 2,
          qtdChamados: 3,
        ),
      ];
    }
    final data = await ApiClient.instance.get('/api/projetos') as List;
    return data.map((e) => Projeto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjetoDetail> detalhe(int id) async {
    final data = await ApiClient.instance.get('/api/projetos/$id');
    return ProjetoDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<Projeto> salvar(Map<String, dynamic> payload, {int? id}) async {
    final data = id == null
        ? await ApiClient.instance.post('/api/projetos', payload)
        : await ApiClient.instance.put('/api/projetos/$id', payload);
    return Projeto.fromJson(data as Map<String, dynamic>);
  }

  Future<void> excluir(int id) => ApiClient.instance.delete('/api/projetos/$id');

  Future<ProjetoAnexo> enviarAnexo(int projetoId, String filePath) async {
    final data = await ApiClient.instance.uploadFile(
      '/api/projetos/$projetoId/anexos',
      fields: const {},
      filePath: filePath,
    );
    return ProjetoAnexo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> excluirAnexo(int anexoId) =>
      ApiClient.instance.delete('/api/projetos/anexos/$anexoId');

  Future<void> vincularChamado(int projetoId, int chamadoCodigo, int? clienteId) =>
      ApiClient.instance.post('/api/projetos/$projetoId/chamados', {
        'chamado_codigo': chamadoCodigo,
        'cliente_id': clienteId,
      });

  Future<void> desvincularChamado(int chamadoCodigo) =>
      ApiClient.instance.delete('/api/projetos/chamados/$chamadoCodigo');
}
