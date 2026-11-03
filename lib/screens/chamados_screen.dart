import 'package:flutter/material.dart';

import '../data/chamado.dart';
import '../data/customer.dart';
import '../data/customers_repository.dart';
import '../data/milvus_repository.dart';
import '../data/projeto.dart';
import '../data/projetos_repository.dart';
import '../theme.dart';
import 'projeto_form_screen.dart';

const _meses = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

class ChamadosScreen extends StatefulWidget {
  const ChamadosScreen({super.key});

  @override
  State<ChamadosScreen> createState() => _ChamadosScreenState();
}

class _ChamadosScreenState extends State<ChamadosScreen> {
  final _repo = MilvusRepository();
  final _projRepo = ProjetosRepository();
  List<Customer> _clientes = [];
  List<Projeto> _projetos = [];
  bool _loadingClientes = true;
  int? _clienteId;
  late int _mes;
  late int _ano;

  Future<ChamadosReport>? _report;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mes = now.month;
    _ano = now.year;
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    try {
      final all = await CustomersRepository().list();
      List<Projeto> projetos = [];
      try {
        projetos = await _projRepo.listar();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        // Só clientes com vínculo Milvus têm relatório de horas.
        _clientes = all.where((c) => c.milvusId != null).toList();
        _projetos = projetos;
        _loadingClientes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingClientes = false);
    }
  }

  void _buscar() {
    if (_clienteId == null) return;
    setState(() => _report = _repo.chamados(_clienteId!, _ano, _mes));
  }

  Future<void> _vincular(Chamado c) async {
    if (c.codigo == null) return;
    if (_projetos.isEmpty) {
      _snack('Cadastre um projeto antes de vincular um chamado.');
      return;
    }
    // Sugere projetos do cliente consultado; se não houver, mostra todos.
    final doCliente = _projetos.where((p) => p.customerId == _clienteId).toList();
    final lista = doCliente.isNotEmpty ? doCliente : _projetos;
    final escolhido = await showModalBottomSheet<Projeto>(
      context: context,
      backgroundColor: ZenpexColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Vincular chamado a um projeto',
                  style: TextStyle(
                      color: ZenpexColors.offWhite, fontWeight: FontWeight.w600)),
            ),
            ...lista.map((p) => ListTile(
                  title: Text(p.nome,
                      style: const TextStyle(color: ZenpexColors.offWhite)),
                  subtitle: Text(p.clienteNome ?? '',
                      style: const TextStyle(color: ZenpexColors.textMuted)),
                  onTap: () => Navigator.pop(ctx, p),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (escolhido == null) return;
    try {
      await _projRepo.vincularChamado(escolhido.id, c.codigo!, _clienteId);
      _buscar();
    } catch (e) {
      _snack('Erro ao vincular: $e');
    }
  }

  Future<void> _desvincular(Chamado c) async {
    if (c.codigo == null) return;
    try {
      await _projRepo.desvincularChamado(c.codigo!);
      _buscar();
    } catch (e) {
      _snack('Erro ao desvincular: $e');
    }
  }

  Future<void> _abrirProjeto(int projetoId) async {
    try {
      final detalhe = await _projRepo.detalhe(projetoId);
      if (!mounted) return;
      final alterou = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ProjetoFormScreen(projeto: detalhe)),
      );
      if (alterou == true) {
        try {
          _projetos = await _projRepo.listar();
        } catch (_) {}
        _buscar();
      }
    } catch (e) {
      _snack('Não foi possível abrir o projeto: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('Chamados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _filtros(),
          Expanded(child: _resultado()),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: ZenpexColors.surface,
      child: Column(
        children: [
          _loadingClientes
              ? const LinearProgressIndicator(color: ZenpexColors.blue)
              : DropdownButtonFormField<int>(
                  initialValue: _clienteId,
                  isExpanded: true,
                  dropdownColor: ZenpexColors.surfaceHigh,
                  style: const TextStyle(color: ZenpexColors.offWhite),
                  hint: const Text('Selecione o cliente',
                      style: TextStyle(color: ZenpexColors.textMuted)),
                  items: _clientes
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nome)))
                      .toList(),
                  onChanged: (v) => setState(() => _clienteId = v),
                  decoration: _dec('Cliente (Milvus)'),
                ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _mes,
                  dropdownColor: ZenpexColors.surfaceHigh,
                  style: const TextStyle(color: ZenpexColors.offWhite),
                  items: [
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(value: m, child: Text(_meses[m - 1])),
                  ],
                  onChanged: (v) => setState(() => _mes = v ?? _mes),
                  decoration: _dec('Mês'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _ano,
                  dropdownColor: ZenpexColors.surfaceHigh,
                  style: const TextStyle(color: ZenpexColors.offWhite),
                  items: [
                    for (var a = DateTime.now().year; a >= DateTime.now().year - 4; a--)
                      DropdownMenuItem(value: a, child: Text('$a')),
                  ],
                  onChanged: (v) => setState(() => _ano = v ?? _ano),
                  decoration: _dec('Ano'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ZenpexColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _clienteId == null ? null : _buscar,
              icon: const Icon(Icons.search),
              label: const Text('Buscar chamados'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultado() {
    if (_report == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Selecione um cliente e o período para ver os chamados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ZenpexColors.textMuted),
          ),
        ),
      );
    }
    return FutureBuilder<ChamadosReport>(
      future: _report,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: ZenpexColors.blue));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Não foi possível carregar.\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: ZenpexColors.textMuted),
              ),
            ),
          );
        }
        final r = snap.data!;
        final temProjeto = r.horasProjeto > 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ZenpexColors.navy, Color(0xFF101830)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: ZenpexColors.lightBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Horas cobráveis — ${_meses[r.mes - 1]}/${r.ano}',
                                style: const TextStyle(
                                    color: ZenpexColors.lightBlue, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              r.horasCobraveisHHMM,
                              style: const TextStyle(
                                fontFamily: monoFamily,
                                fontFamilyFallback: monoFallback,
                                color: ZenpexColors.offWhite,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _mini('Em projeto', r.horasProjetoHHMM,
                          const Color(0xFF8C7CFF)),
                      const SizedBox(width: 10),
                      _mini('Total', r.totalHorasMesHHMM, ZenpexColors.lightBlue),
                    ],
                  ),
                ],
              ),
            ),
            if (temProjeto)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Chamados marcados como projeto saem das horas cobráveis.',
                  style: TextStyle(
                      color: ZenpexColors.textMuted.withValues(alpha: 0.9),
                      fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            _secTitle('Finalizados (${r.finalizadosOperadores.length})'),
            if (r.finalizadosOperadores.isEmpty)
              _vazio('Nenhum chamado finalizado.'),
            ...r.finalizadosOperadores.map((c) => _ChamadoTile(
                  c: c,
                  onVincular: () => _vincular(c),
                  onDesvincular: () => _desvincular(c),
                  onAbrirProjeto: c.projetoId != null
                      ? () => _abrirProjeto(c.projetoId!)
                      : null,
                )),
            if (r.emAbertoOperadores.isNotEmpty) ...[
              const SizedBox(height: 20),
              _secTitle('Em aberto (${r.emAbertoOperadores.length})'),
              ...r.emAbertoOperadores.map((c) => _ChamadoTile(c: c, aberto: true)),
            ],
          ],
        );
      },
    );
  }

  Widget _mini(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                    fontFamily: monoFamily,
                    fontFamilyFallback: monoFallback,
                    color: ZenpexColors.offWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
            ],
          ),
        ),
      );

  Widget _secTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontFamily: monoFamily,
                fontFamilyFallback: monoFallback,
                fontSize: 12,
                letterSpacing: 1.2,
                color: ZenpexColors.textMuted)),
      );

  Widget _vazio(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(color: ZenpexColors.textMuted)),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ZenpexColors.textMuted),
        filled: true,
        fillColor: ZenpexColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

class _ChamadoTile extends StatelessWidget {
  const _ChamadoTile({
    required this.c,
    this.aberto = false,
    this.onVincular,
    this.onDesvincular,
    this.onAbrirProjeto,
  });
  final Chamado c;
  final bool aberto;
  final VoidCallback? onVincular;
  final VoidCallback? onDesvincular;
  final VoidCallback? onAbrirProjeto;

  static const _violeta = Color(0xFF8C7CFF);

  @override
  Widget build(BuildContext context) {
    final emProjeto = c.emProjeto;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emProjeto
            ? _violeta.withValues(alpha: 0.12)
            : ZenpexColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: emProjeto
                ? _violeta.withValues(alpha: 0.5)
                : ZenpexColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.assunto.isEmpty ? '(sem assunto)' : c.assunto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ZenpexColors.offWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ChamadosReport.formatarHoras(
                    aberto ? c.horasDecimal : c.horasMesDecimal),
                style: const TextStyle(
                  fontFamily: monoFamily,
                  fontFamilyFallback: monoFallback,
                  color: ZenpexColors.lightBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (c.codigo != null) '#${c.codigo}',
              if (c.tecnico != null && c.tecnico!.isNotEmpty) c.tecnico!,
              if (aberto) c.status,
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: ZenpexColors.textMuted),
          ),
          if (!aberto) ...[
            const SizedBox(height: 10),
            if (emProjeto)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onAbrirProjeto,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _violeta.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: _violeta.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_special_outlined,
                                size: 14, color: _violeta),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                c.projetoNome ?? 'Projeto',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: _violeta,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_new,
                                size: 12, color: _violeta),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onDesvincular,
                    child: const Text('Desvincular',
                        style: TextStyle(
                            color: ZenpexColors.textMuted, fontSize: 12)),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onVincular,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.add_link, size: 16),
                  label: const Text('Vincular a projeto',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
