import '../config/app_config.dart';
import '../services/api_client.dart';
import 'financeiro.dart';

class FinanceiroRepository {
  Future<List<SaldoConta>> saldosContas() async {
    if (AppConfig.devPreview) return _saldos;
    final data = await ApiClient.instance
        .get('/api/financeiro/dashboard/saldos-contas') as List<dynamic>;
    return data
        .map((e) => SaldoConta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FinAlertas> alertas() async {
    if (AppConfig.devPreview) {
      return FinAlertas(
        recorrenciasAVencer: [
          RecorrenciaAVencer(
            descricao: 'Aluguel do escritório',
            tipo: 'DESPESA',
            valor: 3500,
            dataPrevista: DateTime.now().add(const Duration(days: 5)),
          ),
        ],
      );
    }
    final data = await ApiClient.instance
        .get('/api/financeiro/dashboard/alertas') as Map<String, dynamic>;
    return FinAlertas.fromJson(data);
  }

  Future<List<CategoriaResumo>> porCategoria(DateTime inicio, DateTime fim) async {
    if (AppConfig.devPreview) return _categorias;
    final di = inicio.toIso8601String().split('T').first;
    final df = fim.toIso8601String().split('T').first;
    final data = await ApiClient.instance.get(
      '/api/financeiro/dashboard/por-categoria?data_inicio=$di&data_fim=$df',
    ) as List<dynamic>;
    return data
        .map((e) => CategoriaResumo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Dre> dre(DateTime inicio, DateTime fim) async {
    if (AppConfig.devPreview) {
      return Dre(
        receitaBruta: 40400,
        impostos: 2460,
        lucroBruto: 37940,
        despesasVariaveis: 6200,
        lucroOperacional: 31740,
        despesasFixas: 3500,
        gastosPessoal: 18500,
        resultadoExercicio: 9740,
      );
    }
    final di = inicio.toIso8601String().split('T').first;
    final df = fim.toIso8601String().split('T').first;
    final data = await ApiClient.instance.get(
      '/api/financeiro/relatorios/dre?data_inicio=$di&data_fim=$df',
    ) as Map<String, dynamic>;
    return Dre.fromJson(data);
  }

  Future<List<Transacao>> transacoes({DateTime? inicio, DateTime? fim}) async {
    if (AppConfig.devPreview) return _transacoes;
    final params = <String>[];
    if (inicio != null) {
      params.add('data_inicio=${inicio.toIso8601String().split('T').first}');
    }
    if (fim != null) {
      params.add('data_fim=${fim.toIso8601String().split('T').first}');
    }
    final qs = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await ApiClient.instance
        .get('/api/financeiro/transacoes$qs') as List<dynamic>;
    return data
        .map((e) => Transacao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Contas ----
  Future<List<FinConta>> contas() async {
    if (AppConfig.devPreview) return _contasSample;
    final data =
        await ApiClient.instance.get('/api/financeiro/contas') as List<dynamic>;
    return data.map((e) => FinConta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvarConta(Map<String, dynamic> p, {int? id}) async {
    if (AppConfig.devPreview) return;
    if (id == null) {
      await ApiClient.instance.post('/api/financeiro/contas', p);
    } else {
      await ApiClient.instance.put('/api/financeiro/contas/$id', p);
    }
  }

  Future<void> excluirConta(int id) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.delete('/api/financeiro/contas/$id');
  }

  // ---- Categorias ----
  Future<List<FinCategoria>> categorias() async {
    if (AppConfig.devPreview) return _categoriasSample;
    final data = await ApiClient.instance
        .get('/api/financeiro/categorias') as List<dynamic>;
    return data
        .map((e) => FinCategoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvarCategoria(Map<String, dynamic> p, {int? id}) async {
    if (AppConfig.devPreview) return;
    if (id == null) {
      await ApiClient.instance.post('/api/financeiro/categorias', p);
    } else {
      await ApiClient.instance.put('/api/financeiro/categorias/$id', p);
    }
  }

  Future<void> excluirCategoria(int id) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.delete('/api/financeiro/categorias/$id');
  }

  // ---- Contatos ----
  Future<List<FinContato>> contatos() async {
    if (AppConfig.devPreview) return _contatosSample;
    final data = await ApiClient.instance
        .get('/api/financeiro/contatos') as List<dynamic>;
    return data
        .map((e) => FinContato.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvarContato(Map<String, dynamic> p, {int? id}) async {
    if (AppConfig.devPreview) return;
    if (id == null) {
      await ApiClient.instance.post('/api/financeiro/contatos', p);
    } else {
      await ApiClient.instance.put('/api/financeiro/contatos/$id', p);
    }
  }

  Future<void> excluirContato(int id) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.delete('/api/financeiro/contatos/$id');
  }

  // ---- Lançamentos (criar/editar) ----
  Future<void> salvarTransacao(Map<String, dynamic> p, {int? id}) async {
    if (AppConfig.devPreview) return;
    if (id == null) {
      await ApiClient.instance.post('/api/financeiro/transacoes', p);
    } else {
      await ApiClient.instance.put('/api/financeiro/transacoes/$id', p);
    }
  }

  // ---- Assistente de IA (Gemini via backend) ----
  Future<String> iaResumo() async {
    if (AppConfig.devPreview) {
      await Future.delayed(const Duration(milliseconds: 600));
      return 'No mês, as receitas (R\$ 40.400) superaram as despesas '
          '(R\$ 28.200), com resultado positivo de R\$ 9.740. A maior despesa '
          'foi com pessoal. Atenção ao aluguel que vence em breve.';
    }
    final r = await ApiClient.instance.post('/api/financeiro/ia/resumo', {})
        as Map<String, dynamic>;
    return (r['resumo'] ?? '') as String;
  }

  Future<String> iaPerguntar(String pergunta) async {
    if (AppConfig.devPreview) {
      await Future.delayed(const Duration(milliseconds: 700));
      return 'Com base nos lançamentos, você gastou R\$ 6.200 com fornecedores '
          'neste mês.';
    }
    final r = await ApiClient.instance
        .post('/api/financeiro/ia/perguntar', {'pergunta': pergunta})
        as Map<String, dynamic>;
    return (r['resposta'] ?? '') as String;
  }

  // ---- Recorrências ----
  Future<List<FinRecorrencia>> recorrencias() async {
    if (AppConfig.devPreview) return _recorrenciasSample;
    final data = await ApiClient.instance
        .get('/api/financeiro/recorrencias') as List<dynamic>;
    return data
        .map((e) => FinRecorrencia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvarRecorrencia(Map<String, dynamic> p, {int? id}) async {
    if (AppConfig.devPreview) return;
    if (id == null) {
      await ApiClient.instance.post('/api/financeiro/recorrencias', p);
    } else {
      await ApiClient.instance.put('/api/financeiro/recorrencias/$id', p);
    }
  }

  Future<void> excluirRecorrencia(int id) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.delete('/api/financeiro/recorrencias/$id');
  }

  Future<int> gerarRecorrenciasAgora() async {
    if (AppConfig.devPreview) return 2;
    final r = await ApiClient.instance
        .post('/api/financeiro/recorrencias/gerar-agora', {});
    if (r is Map && r['geradas'] != null) return (r['geradas'] as num).toInt();
    return 0;
  }

  // ---- Importação OFX/Excel ----
  Future<Map<String, dynamic>> importar(
      {required bool ofx, required int contaId, required String filePath}) async {
    if (AppConfig.devPreview) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'total_no_arquivo': 42,
        'total_importadas': 38,
        'total_duplicadas': 3,
        'total_erros': 1,
      };
    }
    final path =
        ofx ? '/api/financeiro/importacao/ofx' : '/api/financeiro/importacao/excel';
    final r = await ApiClient.instance.uploadFile(
      path,
      fields: {'conta_bancaria_id': '$contaId'},
      filePath: filePath,
    );
    return (r as Map<String, dynamic>?) ?? {};
  }

  static final _recorrenciasSample = [
    FinRecorrencia(
      id: 1,
      descricao: 'Aluguel do escritório',
      tipo: 'DESPESA',
      valor: 3500,
      frequencia: 'MENSAL',
      diaDoMes: 5,
      proximaGeracao: DateTime.now().add(const Duration(days: 5)),
      contaNome: 'Sicredi — Corrente',
      categoriaNome: 'Aluguel',
    ),
    FinRecorrencia(
      id: 2,
      descricao: 'Mensalidade Serra Diesel',
      tipo: 'RECEITA',
      valor: 4500,
      frequencia: 'MENSAL',
      diaDoMes: 10,
      proximaGeracao: DateTime.now().add(const Duration(days: 10)),
      contaNome: 'Sicredi — Corrente',
      categoriaNome: 'Serviços prestados',
    ),
  ];

  // ---- amostras para prévia ----
  static final _contasSample = [
    FinConta(id: 1, nome: 'Sicredi — Corrente', tipo: 'CORRENTE', banco: 'Sicredi', saldoInicial: 20000),
    FinConta(id: 2, nome: 'Caixa interno', tipo: 'CAIXA', saldoInicial: 1000),
    FinConta(id: 3, nome: 'Reserva (Poupança)', tipo: 'POUPANCA', banco: 'Sicredi', saldoInicial: 15000),
  ];
  static final _categoriasSample = [
    FinCategoria(id: 1, nome: 'Serviços prestados', tipo: 'RECEITA'),
    FinCategoria(id: 2, nome: 'Licenças/revenda', tipo: 'RECEITA'),
    FinCategoria(id: 3, nome: 'Salários', tipo: 'DESPESA', grupoDre: 'PESSOAL'),
    FinCategoria(id: 4, nome: 'Aluguel', tipo: 'DESPESA', grupoDre: 'DESPESA_FIXA'),
    FinCategoria(id: 5, nome: 'Fornecedores', tipo: 'DESPESA', grupoDre: 'DESPESA_VARIAVEL'),
    FinCategoria(id: 6, nome: 'Impostos', tipo: 'DESPESA', grupoDre: 'IMPOSTO'),
  ];
  static final _contatosSample = [
    FinContato(id: 1, nome: 'Serra Diesel', tipo: 'CLIENTE', documento: '12.345.678/0001-90'),
    FinContato(id: 2, nome: 'Imobiliária Central', tipo: 'FORNECEDOR'),
    FinContato(id: 3, nome: 'Pedro Delagustinhi', tipo: 'SOCIO'),
  ];

  // ---- amostras antigas ----
  static final _saldos = [
    SaldoConta(
        contaId: 1,
        contaNome: 'Sicredi — Corrente',
        contaTipo: 'CORRENTE',
        saldoAtual: 28450.75),
    SaldoConta(
        contaId: 2,
        contaNome: 'Caixa interno',
        contaTipo: 'CAIXA',
        saldoAtual: 1250.00),
    SaldoConta(
        contaId: 3,
        contaNome: 'Reserva (Poupança)',
        contaTipo: 'POUPANCA',
        saldoAtual: 15000.00),
  ];

  static final _categorias = [
    CategoriaResumo(categoriaNome: 'Serviços prestados', tipo: 'RECEITA', total: 32000),
    CategoriaResumo(categoriaNome: 'Licenças/revenda', tipo: 'RECEITA', total: 8400),
    CategoriaResumo(categoriaNome: 'Salários', tipo: 'DESPESA', total: 18500),
    CategoriaResumo(categoriaNome: 'Aluguel', tipo: 'DESPESA', total: 3500),
    CategoriaResumo(categoriaNome: 'Fornecedores', tipo: 'DESPESA', total: 6200),
  ];

  static final _transacoes = [
    Transacao(
        id: 1,
        descricao: 'NF 1042 — Serra Diesel',
        tipo: 'RECEITA',
        valor: 4500,
        data: DateTime.now().subtract(const Duration(days: 1)),
        status: 'CONFIRMADO',
        contaNome: 'Sicredi — Corrente',
        categoriaNome: 'Serviços prestados'),
    Transacao(
        id: 2,
        descricao: 'Aluguel do escritório',
        tipo: 'DESPESA',
        valor: 3500,
        data: DateTime.now().subtract(const Duration(days: 2)),
        status: 'CONFIRMADO',
        contaNome: 'Sicredi — Corrente',
        categoriaNome: 'Aluguel'),
    Transacao(
        id: 3,
        descricao: 'Revenda licenças Microsoft',
        tipo: 'RECEITA',
        valor: 2100,
        data: DateTime.now().subtract(const Duration(days: 4)),
        status: 'CONFIRMADO',
        contaNome: 'Sicredi — Corrente',
        categoriaNome: 'Licenças/revenda'),
    Transacao(
        id: 4,
        descricao: 'Energia elétrica',
        tipo: 'DESPESA',
        valor: 780.45,
        data: DateTime.now().subtract(const Duration(days: 6)),
        status: 'PREVISTO',
        contaNome: 'Sicredi — Corrente',
        categoriaNome: 'Utilidades'),
  ];
}
