/// Cliente do hub (espelha CustomerResponse da API).
class Customer {
  Customer({
    required this.id,
    required this.nome,
    required this.origem,
    required this.isAtivo,
    this.documento,
    this.emailContato,
    this.telefone,
    this.horasContratadasMensais,
    this.milvusId,
  });

  final int id;
  final String nome;
  final String origem; // MANUAL | MILVUS
  final bool isAtivo;
  final String? documento;
  final String? emailContato;
  final String? telefone;
  final double? horasContratadasMensais;
  final int? milvusId;

  bool get isMilvus => origem == 'MILVUS';

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as int,
        nome: (j['nome'] ?? '') as String,
        origem: (j['origem'] ?? 'MANUAL') as String,
        isAtivo: (j['is_ativo'] ?? true) as bool,
        documento: j['documento'] as String?,
        emailContato: j['email_contato'] as String?,
        telefone: j['telefone'] as String?,
        horasContratadasMensais:
            (j['horas_contratadas_mensais'] as num?)?.toDouble(),
        milvusId: j['milvus_id'] as int?,
      );
}
