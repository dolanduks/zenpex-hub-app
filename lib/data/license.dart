import '../widgets/format.dart';

class License {
  License({
    required this.id,
    required this.nomeProduto,
    required this.tipo,
    required this.status,
    required this.diasParaVencimento,
    this.dataVencimento,
    this.dataInicio,
    this.customerId,
    this.customerNome,
    this.categoryId,
    this.categoryNome,
    this.productId,
    this.modelo,
    this.descricao,
    this.destinatariosExtra,
  });

  final int id;
  final String nomeProduto;
  final String tipo; // CLIENTE | INTERNO
  final String status; // ATIVA | CANCELADA
  final int diasParaVencimento;
  final DateTime? dataVencimento;
  final DateTime? dataInicio;
  final int? customerId;
  final String? customerNome;
  final int? categoryId;
  final String? categoryNome;
  final int? productId;
  final String? modelo;
  final String? descricao;
  final String? destinatariosExtra;

  bool get cancelada => status == 'CANCELADA';
  bool get vencida => !cancelada && diasParaVencimento < 0;
  bool get venceEmBreve =>
      !cancelada && diasParaVencimento >= 0 && diasParaVencimento <= 30;

  factory License.fromJson(Map<String, dynamic> j) => License(
        id: j['id'] as int,
        nomeProduto: (j['nome_produto'] ?? '') as String,
        tipo: (j['tipo'] ?? 'CLIENTE') as String,
        status: (j['status'] ?? 'ATIVA') as String,
        diasParaVencimento: (j['dias_para_vencimento'] ?? 0) as int,
        dataVencimento: parseDate(j['data_vencimento']),
        dataInicio: parseDate(j['data_inicio']),
        customerId: j['customer_id'] as int?,
        customerNome: j['customer_nome'] as String?,
        categoryId: j['category_id'] as int?,
        categoryNome: j['category_nome'] as String?,
        productId: j['product_id'] as int?,
        modelo: j['modelo'] as String?,
        descricao: j['descricao'] as String?,
        destinatariosExtra: j['destinatarios_extra'] as String?,
      );
}
