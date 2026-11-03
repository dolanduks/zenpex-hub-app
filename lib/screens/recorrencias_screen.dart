import 'package:flutter/material.dart';

import '../data/financeiro.dart';
import '../data/financeiro_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';
import '../widgets/states.dart';
import 'recorrencia_form_screen.dart';

String freqLabel(String f) => switch (f) {
      'SEMANAL' => 'Semanal',
      'ANUAL' => 'Anual',
      _ => 'Mensal',
    };

class RecorrenciasScreen extends StatefulWidget {
  const RecorrenciasScreen({super.key});

  @override
  State<RecorrenciasScreen> createState() => _RecorrenciasScreenState();
}

class _RecorrenciasScreenState extends State<RecorrenciasScreen> {
  final _repo = FinanceiroRepository();
  late Future<List<FinRecorrencia>> _future;
  bool _gerando = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.recorrencias();
  }

  Future<void> _reload() async {
    final f = _repo.recorrencias();
    setState(() => _future = f);
    await f;
  }

  Future<void> _gerarAgora() async {
    setState(() => _gerando = true);
    try {
      final n = await _repo.gerarRecorrenciasAgora();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$n lançamento(s) gerado(s).')));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  Future<void> _abrir([FinRecorrencia? r]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RecorrenciaFormScreen(recorrencia: r)),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('Recorrências',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: _gerando ? null : _gerarAgora,
            icon: _gerando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: ZenpexColors.lightBlue))
                : const Icon(Icons.play_circle_outline,
                    color: ZenpexColors.lightBlue),
            label: const Text('Gerar agora',
                style: TextStyle(color: ZenpexColors.lightBlue)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ZenpexColors.blue,
        foregroundColor: Colors.white,
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: FutureBuilder<List<FinRecorrencia>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snap.hasError) {
            return ErrorRetry(
                message: 'Não foi possível carregar.\n${snap.error}',
                onRetry: _reload);
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
                icon: Icons.autorenew,
                message: 'Nenhuma recorrência cadastrada.');
          }
          return RefreshIndicator(
            onRefresh: _reload,
            color: ZenpexColors.blue,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _tile(items[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(FinRecorrencia r) {
    final cor = r.isReceita ? ZenpexColors.ok : const Color(0xFFE5484D);
    return Material(
      color: ZenpexColors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrir(r),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ZenpexColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(r.descricao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: ZenpexColors.offWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                  Text('${r.isReceita ? '+' : '-'} ${brMoney(r.valor)}',
                      style:
                          TextStyle(color: cor, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${freqLabel(r.frequencia)}'
                '${r.diaDoMes != null ? ' · dia ${r.diaDoMes}' : ''}'
                ' · próx. ${brDate(r.proximaGeracao)}',
                style: const TextStyle(
                    color: ZenpexColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
