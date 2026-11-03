import '../widgets/format.dart';

class ProjetoServico {
  ProjetoServico({required this.id, required this.nome, this.isAtivo = true});
  final int id;
  final String nome;
  final bool isAtivo;

  factory ProjetoServico.fromJson(Map<String, dynamic> j) => ProjetoServico(
        id: j['id'] as int,
        nome: (j['nome'] ?? '') as String,
        isAtivo: (j['is_ativo'] ?? true) as bool,
      );
}

class ProjetoAnexo {
  ProjetoAnexo({
    required this.id,
    required this.nomeArquivo,
    this.contentType,
    required this.tamanho,
  });
  final int id;
  final String nomeArquivo;
  final String? contentType;
  final int tamanho;

  factory ProjetoAnexo.fromJson(Map<String, dynamic> j) => ProjetoAnexo(
        id: j['id'] as int,
        nomeArquivo: (j['nome_arquivo'] ?? 'arquivo') as String,
        contentType: j['content_type'] as String?,
        tamanho: (j['tamanho'] as num?)?.toInt() ?? 0,
      );
}

class ProjetoChamadoLink {
  ProjetoChamadoLink({required this.id, required this.chamadoCodigo, this.clienteId});
  final int id;
  final int chamadoCodigo;
  final int? clienteId;

  factory ProjetoChamadoLink.fromJson(Map<String, dynamic> j) => ProjetoChamadoLink(
        id: j['id'] as int,
        chamadoCodigo: (j['chamado_codigo'] as num).toInt(),
        clienteId: (j['cliente_id'] as num?)?.toInt(),
      );
}

class Projeto {
  Projeto({
    required this.id,
    required this.customerId,
    this.servicoId,
    required this.nome,
    this.descricao,
    this.valor,
    this.horas,
    this.contatoCliente,
    this.data,
    this.clienteNome,
    this.servicoNome,
    this.qtdAnexos = 0,
    this.qtdChamados = 0,
  });

  final int id;
  final int customerId;
  final int? servicoId;
  final String nome;
  final String? descricao;
  final double? valor;
  final double? horas;
  final String? contatoCliente;
  final DateTime? data;
  final String? clienteNome;
  final String? servicoNome;
  final int qtdAnexos;
  final int qtdChamados;

  factory Projeto.fromJson(Map<String, dynamic> j) => Projeto(
        id: j['id'] as int,
        customerId: (j['customer_id'] as num).toInt(),
        servicoId: (j['servico_id'] as num?)?.toInt(),
        nome: (j['nome'] ?? '') as String,
        descricao: j['descricao'] as String?,
        valor: (j['valor'] as num?)?.toDouble(),
        horas: (j['horas'] as num?)?.toDouble(),
        contatoCliente: j['contato_cliente'] as String?,
        data: parseDate(j['data']),
        clienteNome: j['cliente_nome'] as String?,
        servicoNome: j['servico_nome'] as String?,
        qtdAnexos: (j['qtd_anexos'] as num?)?.toInt() ?? 0,
        qtdChamados: (j['qtd_chamados'] as num?)?.toInt() ?? 0,
      );
}

class ProjetoDetail extends Projeto {
  ProjetoDetail({
    required super.id,
    required super.customerId,
    super.servicoId,
    required super.nome,
    super.descricao,
    super.valor,
    super.horas,
    super.contatoCliente,
    super.data,
    super.clienteNome,
    super.servicoNome,
    super.qtdAnexos,
    super.qtdChamados,
    this.anexos = const [],
    this.chamados = const [],
  });

  final List<ProjetoAnexo> anexos;
  final List<ProjetoChamadoLink> chamados;

  factory ProjetoDetail.fromJson(Map<String, dynamic> j) => ProjetoDetail(
        id: j['id'] as int,
        customerId: (j['customer_id'] as num).toInt(),
        servicoId: (j['servico_id'] as num?)?.toInt(),
        nome: (j['nome'] ?? '') as String,
        descricao: j['descricao'] as String?,
        valor: (j['valor'] as num?)?.toDouble(),
        horas: (j['horas'] as num?)?.toDouble(),
        contatoCliente: j['contato_cliente'] as String?,
        data: parseDate(j['data']),
        clienteNome: j['cliente_nome'] as String?,
        servicoNome: j['servico_nome'] as String?,
        qtdAnexos: (j['qtd_anexos'] as num?)?.toInt() ?? 0,
        qtdChamados: (j['qtd_chamados'] as num?)?.toInt() ?? 0,
        anexos: ((j['anexos'] ?? []) as List)
            .map((e) => ProjetoAnexo.fromJson(e as Map<String, dynamic>))
            .toList(),
        chamados: ((j['chamados'] ?? []) as List)
            .map((e) => ProjetoChamadoLink.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
