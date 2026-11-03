import 'package:flutter/material.dart';

import '../data/customer.dart';
import '../data/customers_repository.dart';
import '../theme.dart';
import '../widgets/states.dart';
import 'cliente_detail_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _repo = CustomersRepository();
  late Future<List<Customer>> _future;
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
        title: const Text('Clientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ZenpexColors.blue,
        foregroundColor: Colors.white,
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ClienteDetailScreen()),
          );
          if (changed == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(color: ZenpexColors.offWhite),
              decoration: InputDecoration(
                hintText: 'Buscar cliente…',
                hintStyle: const TextStyle(color: ZenpexColors.textMuted),
                prefixIcon:
                    const Icon(Icons.search, color: ZenpexColors.textMuted),
                filled: true,
                fillColor: ZenpexColors.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snap.hasError) {
                  return ErrorRetry(
                    message: '$_erro${snap.error}',
                    onRetry: _reload,
                  );
                }
                final all = snap.data ?? [];
                final items = _query.isEmpty
                    ? all
                    : all
                        .where((c) =>
                            c.nome.toLowerCase().contains(_query) ||
                            (c.documento ?? '').toLowerCase().contains(_query))
                        .toList();
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_outlined,
                    message: 'Nenhum cliente encontrado.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  color: ZenpexColors.blue,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ClienteTile(
                      customer: items[i],
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                ClienteDetailScreen(customer: items[i]),
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

  static const _erro = 'Não foi possível carregar os clientes.\n';
}

class _ClienteTile extends StatelessWidget {
  const _ClienteTile({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ZenpexColors.blue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  customer.nome.isNotEmpty
                      ? customer.nome[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: ZenpexColors.lightBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ZenpexColors.offWhite,
                            ),
                          ),
                        ),
                        if (!customer.isAtivo) ...[
                          const SizedBox(width: 8),
                          _Chip(text: 'Inativo', color: ZenpexColors.textMuted),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      customer.documento?.isNotEmpty == true
                          ? customer.documento!
                          : (customer.emailContato ?? 'Sem documento'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ZenpexColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _Chip(
                text: customer.isMilvus ? 'Milvus' : 'Manual',
                color: customer.isMilvus
                    ? const Color(0xFF3CC48A)
                    : ZenpexColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
