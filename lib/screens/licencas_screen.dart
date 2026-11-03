import 'package:flutter/material.dart';

import '../data/license.dart';
import '../data/licenses_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';
import '../widgets/states.dart';
import 'licenca_detail_screen.dart';

class LicencasScreen extends StatefulWidget {
  const LicencasScreen({super.key});

  @override
  State<LicencasScreen> createState() => _LicencasScreenState();
}

class _LicencasScreenState extends State<LicencasScreen> {
  final _repo = LicensesRepository();
  late Future<List<License>> _future;
  String _query = '';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('Licenças',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ZenpexColors.blue,
        foregroundColor: Colors.white,
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const LicencaDetailScreen()),
          );
          if (changed == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(color: ZenpexColors.offWhite),
              decoration: InputDecoration(
                hintText: 'Buscar licença…',
                hintStyle: const TextStyle(color: ZenpexColors.textMuted),
                prefixIcon:
                    const Icon(Icons.search, color: ZenpexColors.textMuted),
                filled: true,
                fillColor: ZenpexColors.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<License>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snap.hasError) {
                  return ErrorRetry(
                    message:
                        'Não foi possível carregar as licenças.\n${snap.error}',
                    onRetry: _reload,
                  );
                }
                final all = snap.data ?? [];
                final items = _query.isEmpty
                    ? all
                    : all
                        .where((l) =>
                            l.nomeProduto.toLowerCase().contains(_query) ||
                            (l.customerNome ?? '')
                                .toLowerCase()
                                .contains(_query))
                        .toList();
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.verified_outlined,
                    message: 'Nenhuma licença encontrada.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  color: ZenpexColors.blue,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _LicenseTile(
                      license: items[i],
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                LicencaDetailScreen(license: items[i]),
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

class _LicenseTile extends StatelessWidget {
  const _LicenseTile({required this.license, required this.onTap});

  final License license;
  final VoidCallback onTap;

  ({String text, Color color}) get _badge {
    if (license.cancelada) {
      return (text: 'Cancelada', color: ZenpexColors.textMuted);
    }
    if (license.vencida) {
      return (text: 'Vencida', color: const Color(0xFFE5484D));
    }
    if (license.venceEmBreve) {
      return (
        text: 'Vence em ${license.diasParaVencimento}d',
        color: const Color(0xFFF2994A)
      );
    }
    return (text: '${license.diasParaVencimento}d', color: ZenpexColors.ok);
  }

  @override
  Widget build(BuildContext context) {
    final b = _badge;
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
                      license.nomeProduto,
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
                    child: Text(
                      b.text,
                      style: TextStyle(
                        fontSize: 11,
                        color: b.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    license.tipo == 'INTERNO'
                        ? Icons.business_outlined
                        : Icons.person_outline,
                    size: 14,
                    color: ZenpexColors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      license.tipo == 'INTERNO'
                          ? 'Interno'
                          : (license.customerNome ?? 'Cliente'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: ZenpexColors.textMuted),
                    ),
                  ),
                  Text(
                    'Venc. ${brDate(license.dataVencimento)}',
                    style: const TextStyle(
                        fontSize: 12, color: ZenpexColors.textMuted),
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
