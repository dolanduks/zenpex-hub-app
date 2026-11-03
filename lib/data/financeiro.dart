import '../widgets/format.dart';

class SaldoConta {
  SaldoConta({
    required this.contaId,
    required this.contaNome,
    required this.contaTipo,
    required this.saldoAtual,
  });
  final int contaId;
  final String contaNome;
  final String contaTipo; // CORRENTE/POUPANCA/CAIXA/INVESTIMENTO
  final double saldoAtual;

  factory SaldoConta.fromJson(Map<String, dynamic> j) => SaldoConta(
        contaId: j['conta_id'] as int,
        contaNome: (j['conta_nome'] ?? '') as String,
        contaTipo: (j['conta_tipo'] ?? '') as String,
        saldoAtual: (j['saldo_atual'] as num?)?.toDouble() ?? 0,
      );
}

class CategoriaResumo {
  CategoriaResumo({
    required this.categoriaNome,
    required this.tipo,
    required this.total,
  });
  final String categoriaNome;
  final String tipo; // RECEITA/DESPESA
  final double total;

  bool get isReceita => tipo == 'RECEITA';

  factory CategoriaResumo.fromJson(Map<String, dynamic> j) => CategoriaResumo(
        categoriaNome: (j['categoria_nome'] ?? 'Sem categoria') as String,
        tipo: (j['tipo'] ?? 'DESPESA') as String,
        total: (j['total'] as num?)?.toDouble() ?? 0,
      );
}

class RecorrenciaAVencer {
  RecorrenciaAVencer({
    required this.descricao,
    required this.tipo,
    required this.valor,
    this.dataPrevista,
  });
  final String descricao;
  final String tipo;
  final double valor;
  final DateTime? dataPrevista;

  factory RecorrenciaAVencer.fromJson(Map<String, dynamic> j) =>
      RecorrenciaAVencer(
        descricao: (j['descricao'] ?? '') as String,
        tipo: (j['tipo'] ?? 'DESPESA') as String,
        valor: (j['valor'] as num?)?.toDouble() ?? 0,
        dataPrevista: parseDate(j['data_prevista']),
      );
}

class FinAlertas {
  FinAlertas({
    this.saldoNegativoEm,
    this.saldoProjetadoNoDia,
    required this.recorrenciasAVencer,
  });
  final DateTime? saldoNegativoEm;
  final double? saldoProjetadoNoDia;
  final List<RecorrenciaAVencer> recorrenciasAVencer;

  bool get temAlerta =>
      saldoNegativoEm != null || recorrenciasAVencer.isNotEmpty;

  factory FinAlertas.fromJson(Map<String, dynamic> j) => FinAlertas(
        saldoNegativoEm: parseDate(j['saldo_negativo_em']),
        saldoProjetadoNoDia: (j['saldo_projetado_no_dia'] as num?)?.toDouble(),
        recorrenciasAVencer: ((j['recorrencias_a_vencer'] ?? []) as List)
            .map((e) => RecorrenciaAVencer.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FinConta {
  FinConta({
    required this.id,
    required this.nome,
    required this.tipo,
    this.banco,
    this.saldoInicial = 0,
    this.isAtiva = true,
  });
  final int id;
  final String nome;
  final String tipo; // CORRENTE/POUPANCA/CAIXA/INVESTIMENTO
  final String? banco;
  final double saldoInicial;
  final bool isAtiva;

  factory FinConta.fromJson(Map<String, dynamic> j) => FinConta(
        id: j['id'] as int,
        nome: (j['nome'] ?? '') as String,
        tipo: (j['tipo'] ?? 'CORRENTE') as String,
        banco: j['banco'] as String?,
        saldoInicial: (j['saldo_inicial'] as num?)?.toDouble() ?? 0,
        isAtiva: (j['is_ativa'] ?? true) as bool,
      );
}

class FinCategoria {
  FinCategoria({
    required this.id,
    required this.nome,
    required this.tipo,
    this.grupoDre,
    this.isAtiva = true,
  });
  final int id;
  final String nome;
  final String tipo; // RECEITA/DESPESA
  final String? grupoDre;
  final bool isAtiva;

  bool get isReceita => tipo == 'RECEITA';

  factory FinCategoria.fromJson(Map<String, dynamic> j) => FinCategoria(
        id: j['id'] as int,
        nome: (j['nome'] ?? '') as String,
        tipo: (j['tipo'] ?? 'DESPESA') as String,
        grupoDre: j['grupo_dre'] as String?,
        isAtiva: (j['is_ativa'] ?? true) as bool,
      );
}

class FinContato {
  FinContato({
    required this.id,
    required this.nome,
    required this.tipo,
    this.documento,
    this.email,
    this.telefone,
    this.isAtivo = true,
  });
  final int id;
  final String nome;
  final String tipo; // CLIENTE/FORNECEDOR/COLABORADOR/SOCIO/OUTRO
  final String? documento;
  final String? email;
  final String? telefone;
  final bool isAtivo;

  factory FinContato.fromJson(Map<String, dynamic> j) => FinContato(
        id: j['id'] as int,
        nome: (j['nome'] ?? '') as String,
        tipo: (j['tipo'] ?? 'OUTRO') as String,
        documento: j['documento'] as String?,
        email: j['email'] as String?,
        telefone: j['telefone'] as String?,
        isAtivo: (j['is_ativo'] ?? true) as bool,
      );
}

class FinRecorrencia {
  FinRecorrencia({
    required this.id,
    required this.descricao,
    required this.tipo,
    required this.valor,
    required this.frequencia,
    this.diaDoMes,
    this.dataInicio,
    this.dataFim,
    this.proximaGeracao,
    this.isAtiva = true,
    this.contaBancariaId,
    this.categoriaId,
    this.contatoId,
    this.contaNome,
    this.categoriaNome,
    this.observacoes,
  });
  final int id;
  final String descricao;
  final String tipo; // RECEITA/DESPESA
  final double valor;
  final String frequencia; // SEMANAL/MENSAL/ANUAL
  final int? diaDoMes;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final DateTime? proximaGeracao;
  final bool isAtiva;
  final int? contaBancariaId;
  final int? categoriaId;
  final int? contatoId;
  final String? contaNome;
  final String? categoriaNome;
  final String? observacoes;

  bool get isReceita => tipo == 'RECEITA';

  factory FinRecorrencia.fromJson(Map<String, dynamic> j) => FinRecorrencia(
        id: j['id'] as int,
        descricao: (j['descricao'] ?? '') as String,
        tipo: (j['tipo'] ?? 'DESPESA') as String,
        valor: (j['valor'] as num?)?.toDouble() ?? 0,
        frequencia: (j['frequencia'] ?? 'MENSAL') as String,
        diaDoMes: j['dia_do_mes'] as int?,
        dataInicio: parseDate(j['data_inicio']),
        dataFim: parseDate(j['data_fim']),
        proximaGeracao: parseDate(j['proxima_geracao']),
        isAtiva: (j['is_ativa'] ?? true) as bool,
        contaBancariaId: j['conta_bancaria_id'] as int?,
        categoriaId: j['categoria_id'] as int?,
        contatoId: j['contato_id'] as int?,
        contaNome: j['conta_nome'] as String?,
        categoriaNome: j['categoria_nome'] as String?,
        observacoes: j['observacoes'] as String?,
      );
}

class Dre {
  Dre({
    required this.receitaBruta,
    required this.impostos,
    required this.lucroBruto,
    required this.despesasVariaveis,
    required this.lucroOperacional,
    required this.despesasFixas,
    required this.gastosPessoal,
    required this.resultadoExercicio,
  });
  final double receitaBruta;
  final double impostos;
  final double lucroBruto;
  final double despesasVariaveis;
  final double lucroOperacional;
  final double despesasFixas;
  final double gastosPessoal;
  final double resultadoExercicio;

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

  factory Dre.fromJson(Map<String, dynamic> j) => Dre(
        receitaBruta: _d(j['receita_bruta']),
        impostos: _d(j['impostos']),
        lucroBruto: _d(j['lucro_bruto']),
        despesasVariaveis: _d(j['despesas_variaveis']),
        lucroOperacional: _d(j['lucro_operacional']),
        despesasFixas: _d(j['despesas_fixas']),
        gastosPessoal: _d(j['gastos_pessoal']),
        resultadoExercicio: _d(j['resultado_exercicio']),
      );
}

class Transacao {
  Transacao({
    required this.id,
    required this.descricao,
    required this.tipo,
    required this.valor,
    this.data,
    required this.status,
    this.contaNome,
    this.categoriaNome,
    this.contatoNome,
    this.contaBancariaId,
    this.categoriaId,
    this.contatoId,
    this.observacoes,
  });
  final int id;
  final String descricao;
  final String tipo; // RECEITA/DESPESA
  final double valor;
  final DateTime? data;
  final String status; // PREVISTO/CONFIRMADO/CONCILIADO
  final String? contaNome;
  final String? categoriaNome;
  final String? contatoNome;
  final int? contaBancariaId;
  final int? categoriaId;
  final int? contatoId;
  final String? observacoes;

  bool get isReceita => tipo == 'RECEITA';

  factory Transacao.fromJson(Map<String, dynamic> j) => Transacao(
        id: j['id'] as int,
        descricao: (j['descricao'] ?? '') as String,
        tipo: (j['tipo'] ?? 'DESPESA') as String,
        valor: (j['valor'] as num?)?.toDouble() ?? 0,
        data: parseDate(j['data']),
        status: (j['status'] ?? '') as String,
        contaNome: j['conta_nome'] as String?,
        categoriaNome: j['categoria_nome'] as String?,
        contatoNome: j['contato_nome'] as String?,
        contaBancariaId: j['conta_bancaria_id'] as int?,
        categoriaId: j['categoria_id'] as int?,
        contatoId: j['contato_id'] as int?,
        observacoes: j['observacoes'] as String?,
      );
}
