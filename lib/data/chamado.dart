class Chamado {
  Chamado({
    this.codigo,
    required this.assunto,
    this.tecnico,
    required this.status,
    this.dataCriacao,
    this.dataSolucao,
    required this.totalHoras,
    required this.horasDecimal,
    required this.horasMesDecimal,
    this.projetoId,
    this.projetoNome,
  });

  final int? codigo;
  final String assunto;
  final String? tecnico;
  final String status;
  final String? dataCriacao;
  final String? dataSolucao;
  final String totalHoras;
  final double horasDecimal;
  final double horasMesDecimal;

  /// Quando vinculado a um projeto: o chamado sai das horas cobráveis do mês
  /// (vira "hora de projeto") e ganha a tag/cor de projeto na lista.
  final int? projetoId;
  final String? projetoNome;

  bool get emProjeto => projetoId != null;

  factory Chamado.fromJson(Map<String, dynamic> j) => Chamado(
        codigo: j['codigo'] as int?,
        assunto: (j['assunto'] ?? '') as String,
        tecnico: j['tecnico'] as String?,
        status: (j['status'] ?? '') as String,
        dataCriacao: j['data_criacao'] as String?,
        dataSolucao: j['data_solucao'] as String?,
        totalHoras: (j['total_horas'] ?? '0:00:00') as String,
        horasDecimal: (j['horas_decimal'] as num?)?.toDouble() ?? 0,
        horasMesDecimal: (j['horas_mes_decimal'] as num?)?.toDouble() ?? 0,
        projetoId: (j['projeto_id'] as num?)?.toInt(),
        projetoNome: j['projeto_nome'] as String?,
      );
}

class ChamadosReport {
  ChamadosReport({
    required this.clienteNome,
    required this.ano,
    required this.mes,
    required this.chamados,
    required this.emAberto,
  });

  final String clienteNome;
  final int ano;
  final int mes;
  final List<Chamado> chamados;
  final List<Chamado> emAberto;

  // Regra de negócio (igual ao hub web, MilvusHorasReport.tsx): o relatório de
  // horas considera APENAS os operadores Pedro e Marco. Casa por substring
  // porque no Milvus o "Marco" aparece como "Marco Sirtoli Sirtoli".
  static bool ehOperadorPadrao(String? tecnico) {
    if (tecnico == null) return false;
    final n = tecnico.toLowerCase();
    return n.contains('pedro') || n.contains('marco');
  }

  /// Chamados finalizados que entram no relatório (só Pedro/Marco).
  List<Chamado> get finalizadosOperadores =>
      chamados.where((c) => ehOperadorPadrao(c.tecnico)).toList();

  /// Chamados em aberto que entram no relatório (só Pedro/Marco).
  List<Chamado> get emAbertoOperadores =>
      emAberto.where((c) => ehOperadorPadrao(c.tecnico)).toList();

  double get totalHorasMes =>
      finalizadosOperadores.fold(0.0, (s, c) => s + c.horasMesDecimal);

  /// Finalizados vinculados a um projeto (saem das horas cobráveis).
  List<Chamado> get finalizadosEmProjeto =>
      finalizadosOperadores.where((c) => c.emProjeto).toList();

  /// Horas lançadas em projetos (custo Zenpex, fora do contrato do mês).
  double get horasProjeto =>
      finalizadosEmProjeto.fold(0.0, (s, c) => s + c.horasMesDecimal);

  /// Horas cobráveis = total do mês menos as horas que estão em projeto.
  double get horasCobraveis => totalHorasMes - horasProjeto;

  double get horasAcumuladasEmAberto =>
      emAbertoOperadores.fold(0.0, (s, c) => s + c.horasDecimal);

  /// Total do mês em "H:MM" (igual ao hub: ex. 92:32), arredondando ao minuto.
  String get totalHorasMesHHMM => formatarHoras(totalHorasMes);
  String get horasProjetoHHMM => formatarHoras(horasProjeto);
  String get horasCobraveisHHMM => formatarHoras(horasCobraveis);

  static String formatarHoras(double horasDecimal) {
    final totalMin = (horasDecimal * 60).round();
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  factory ChamadosReport.fromJson(Map<String, dynamic> j) => ChamadosReport(
        clienteNome: (j['cliente_nome'] ?? '') as String,
        ano: (j['ano'] ?? 0) as int,
        mes: (j['mes'] ?? 0) as int,
        chamados: ((j['chamados'] ?? []) as List)
            .map((e) => Chamado.fromJson(e as Map<String, dynamic>))
            .toList(),
        emAberto: ((j['chamados_em_aberto'] ?? []) as List)
            .map((e) => Chamado.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
