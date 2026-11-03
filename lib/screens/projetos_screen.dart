import 'package:flutter/material.dart';

import '../data/projeto.dart';
import '../data/projetos_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';
import '../widgets/states.dart';
import 'projeto_form_screen.dart';

class ProjetosScreen extends StatefulWidget {
  const ProjetosScreen({super.key});

  @override
  State<ProjetosScreen> createState() => _ProjetosScreenState();
}

class _ProjetosScreenState extends State<ProjetosScreen> {
  final _repo = ProjetosRepository();
  late Future<List<Projeto>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.listar();
  }

  Future<void> _reload() async {
    setState(() => _future = _repo.listar());
  }

  Future<void> _abrirForm([Projeto? p]) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProjetoFormScreen(projeto: p)),
    );
    if (ok == true) _reload();
  }

  Future<void> _excluir(Projeto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZenpexColors.surfaceHigh,
        title: const Text('Excluir projeto',
            style: TextStyle(color: ZenpexColors.offWhite)),
        content: Text('Excluir "${p.nome}"? Os anexos também serão removidos.',
            style: const TextStyle(color: ZenpexColors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEB6B4D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.excluir(p.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('Projetos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ZenpexColors.blue,
        foregroundColor: Colors.white,
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo projeto'),
      ),
      body: FutureBuilder<List<Projeto>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snap.hasError) {
            return ErrorRetry(message: 'Não foi possível carregar.', onRetry: _reload);
          }
          final projetos = snap.data ?? [];
          if (projetos.isEmpty) {
            return const EmptyState(
                icon: Icons.folder_outlined,
                message: 'Nenhum projeto cadastrado ainda.');
          }
          return RefreshIndicator(
            onRefresh: _reload,
            color: ZenpexColors.blue,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: projetos.length,
              itemBuilder: (_, i) => _ProjetoCard(
                p: projetos[i],
                onTap: () => _abrirForm(projetos[i]),
                onDelete: () => _excluir(projetos[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProjetoCard extends StatelessWidget {
  const _ProjetoCard({required this.p, required this.onTap, required this.onDelete});
  final Projeto p;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ZenpexColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZenpexColors.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.nome,
                          style: const TextStyle(
                              color: ZenpexColors.offWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: ZenpexColors.textMuted),
                    ),
                  ],
                ),
                Text(p.clienteNome ?? 'Sem cliente',
                    style: const TextStyle(color: ZenpexColors.textMuted)),
                if (p.servicoNome != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ZenpexColors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: ZenpexColors.blue.withValues(alpha: 0.4)),
                    ),
                    child: Text(p.servicoNome!,
                        style: const TextStyle(
                            color: ZenpexColors.lightBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
                if (p.descricao != null && p.descricao!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(p.descricao!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ZenpexColors.textMuted, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _info('Valor', brMoney(p.valor)),
                    _info('Horas', p.horas != null ? '${p.horas}h' : '—'),
                    _info('Data', brDate(p.data)),
                  ],
                ),
                if (p.qtdChamados > 0 || p.qtdAnexos > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    [
                      if (p.qtdChamados > 0) '${p.qtdChamados} chamado(s)',
                      if (p.qtdAnexos > 0) '${p.qtdAnexos} documento(s)',
                    ].join('  ·  '),
                    style: const TextStyle(color: ZenpexColors.textMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: ZenpexColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: ZenpexColors.offWhite, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
