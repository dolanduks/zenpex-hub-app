import 'package:flutter/material.dart';

import '../data/nfse.dart';
import '../data/nfse_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';
import '../widgets/states.dart';
import 'nfse_detail_screen.dart';

({String label, Color color}) nfseBadge(String status) {
  switch (status) {
    case 'EMITIDA':
      return (label: 'Emitida', color: ZenpexColors.ok);
    case 'REJEITADA':
      return (label: 'Rejeitada', color: const Color(0xFFE5484D));
    case 'PROCESSANDO':
      return (label: 'Processando', color: const Color(0xFFF2994A));
    case 'CANCELADA':
      return (label: 'Cancelada', color: ZenpexColors.textMuted);
    default:
      return (label: 'Rascunho', color: ZenpexColors.blue);
  }
}

class NfseScreen extends StatefulWidget {
  const NfseScreen({super.key});

  @override
  State<NfseScreen> createState() => _NfseScreenState();
}

class _NfseScreenState extends State<NfseScreen> {
  final _repo = NfseRepository();
  late Future<List<Nfse>> _future;
  String? _filtro; // null = todas

  @override
  void initState() {
    super.initState();
    _future = _repo.list();
  }

  Future<void> _reload() async {
    final f = _repo.list();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    const filtros = [
      (null, 'Todas'),
      ('RASCUNHO', 'Rascunhos'),
      ('EMITIDA', 'Emitidas'),
      ('REJEITADA', 'Rejeitadas'),
      ('CANCELADA', 'Canceladas'),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('NFS-e',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final (value, label) in filtros)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filtro == value,
                      onSelected: (_) => setState(() => _filtro = value),
                      backgroundColor: ZenpexColors.surfaceHigh,
                      selectedColor: ZenpexColors.blue.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: _filtro == value
                            ? ZenpexColors.lightBlue
                            : ZenpexColors.textMuted,
                      ),
                      side: BorderSide(
                        color: _filtro == value
                            ? ZenpexColors.blue
                            : ZenpexColors.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Nfse>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snap.hasError) {
                  return ErrorRetry(
                    message: 'Não foi possível carregar as notas.\n${snap.error}',
                    onRetry: _reload,
                  );
                }
                final all = snap.data ?? [];
                final items =
                    _filtro == null ? all : all.where((n) => n.status == _filtro).toList();
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'Nenhuma nota neste filtro.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  color: ZenpexColors.blue,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _NfseTile(
                      nfse: items[i],
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => NfseDetailScreen(nfse: items[i]),
                          ),
                        );
                        if (changed == true) _reload();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NfseTile extends StatelessWidget {
  const _NfseTile({required this.nfse, required this.onTap});
  final Nfse nfse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = nfseBadge(nfse.status);
    return Material(
      color: ZenpexColors.surfaceHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZenpexColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nfse.clienteNome ?? 'Cliente',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ZenpexColors.offWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: b.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(b.label,
                        style: TextStyle(
                            fontSize: 11,
                            color: b.color,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                nfse.descricao,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, color: ZenpexColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    nfse.numeroNfse ?? 'Comp. ${brDate(nfse.competencia)}',
                    style: const TextStyle(
                        fontSize: 12, color: ZenpexColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    brMoney(nfse.valorServico),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ZenpexColors.offWhite),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
