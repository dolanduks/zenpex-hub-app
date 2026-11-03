import '../widgets/format.dart';

class Nfse {
  Nfse({
    required this.id,
    required this.status,
    required this.descricao,
    required this.valorServico,
    this.competencia,
    this.customerId,
    this.clienteNome,
    this.numeroNfse,
    this.chaveAcesso,
    this.emitidaEm,
    this.canceladaEm,
    this.mensagemErro,
    this.emailDestinatarios,
    this.emailEnviadoEm,
    this.temPdf = false,
  });

  final int id;
  final String status; // RASCUNHO/PROCESSANDO/EMITIDA/REJEITADA/CANCELADA
  final String descricao;
  final double valorServico;
  final DateTime? competencia;
  final int? customerId;
  final String? clienteNome;
  final String? numeroNfse;
  final String? chaveAcesso;
  final DateTime? emitidaEm;
  final DateTime? canceladaEm;
  final String? mensagemErro;
  final String? emailDestinatarios;
  final DateTime? emailEnviadoEm;
  final bool temPdf;

  bool get isRascunho => status == 'RASCUNHO' || status == 'REJEITADA';
  bool get isEmitida => status == 'EMITIDA';

  factory Nfse.fromJson(Map<String, dynamic> j) => Nfse(
        id: j['id'] as int,
        status: (j['status'] ?? 'RASCUNHO') as String,
        descricao: (j['descricao'] ?? '') as String,
        valorServico: (j['valor_servico'] as num?)?.toDouble() ?? 0,
        competencia: parseDate(j['competencia']),
        customerId: j['customer_id'] as int?,
        clienteNome: j['cliente_nome'] as String?,
        numeroNfse: j['numero_nfse'] as String?,
        chaveAcesso: j['chave_acesso'] as String?,
        emitidaEm: parseDate(j['emitida_em']),
        canceladaEm: parseDate(j['cancelada_em']),
        mensagemErro: j['mensagem_erro'] as String?,
        emailDestinatarios: j['email_destinatarios'] as String?,
        emailEnviadoEm: parseDate(j['email_enviado_em']),
        temPdf: (j['tem_pdf'] ?? false) as bool,
      );
}
