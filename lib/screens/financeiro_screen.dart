import 'package:flutter/material.dart';

import '../data/financeiro.dart';
import '../data/financeiro_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';
import '../widgets/states.dart';
import 'cadastros_screen.dart';
import 'ia_screen.dart';
import 'importacao_screen.dart';
import 'recorrencias_screen.dart';
import 'transacao_form_screen.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  final _repo = FinanceiroRepository();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ZenpexColors.surface,
          title: const Text('Financeiro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              tooltip: 'Assistente IA',
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IaScreen()),
              ),
            ),
            PopupMenuButton<String>(
              color: ZenpexColors.surfaceHigh,
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                final Widget tela = switch (v) {
                  'recorrencias' => const RecorrenciasScreen(),
                  'importar' => const ImportacaoScreen(),
                  _ => const CadastrosScreen(),
                };
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => tela));
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'cadastros', child: Text('Cadastros')),
                PopupMenuItem(
                    value: 'recorrencias', child: Text('Recorrências')),
                PopupMenuItem(value: 'importar', child: Text('Importar extrato')),
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: ZenpexColors.lightBlue,
            unselectedLabelColor: ZenpexColors.textMuted,
            indicatorColor: ZenpexColors.blue,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Lançamentos'),
              Tab(text: 'Relatórios'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ResumoTab(repo: _repo),
            _LancamentosTab(repo: _repo),
            _RelatoriosTab(repo: _repo),
          ],
        ),
      ),
    );
  }
}

class _ResumoTab extends StatefulWidget {
  const _ResumoTab({required this.repo});
  final FinanceiroRepository repo;
  @override
  State<_ResumoTab> createState() => _ResumoTabState();
}

class _ResumoTabState extends State<_ResumoTab> {
  late Future<_ResumoData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ResumoData> _load() async {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1);
    final fim = DateTime(now.year, now.month + 1, 0);
    final saldos = await widget.repo.saldosContas();
    final alertas = await widget.repo.alertas();
    final cats = await widget.repo.porCategoria(inicio, fim);
    return _ResumoData(saldos: saldos, alertas: alertas, categorias: cats);
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ResumoData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snap.hasError) {
          return ErrorRetry(
              message: 'Não foi possível carregar o resumo.\n${snap.error}',
              onRetry: _reload);
        }
        final d = snap.data!;
        final saldoTotal =
            d.saldos.fold(0.0, (s, c) => s + c.saldoAtual);
        final receitas = d.categorias
            .where((c) => c.isReceita)
            .fold(0.0, (s, c) => s + c.total);
        final despesas = d.categorias
            .where((c) => !c.isReceita)
            .fold(0.0, (s, c) => s + c.total);
        return RefreshIndicator(
          onRefresh: _reload,
          color: ZenpexColors.blue,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Saldo total
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [ZenpexColors.navy, Color(0xFF101830)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo total em contas',
                        style: TextStyle(
                            color: ZenpexColors.lightBlue, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(brMoney(saldoTotal),
                        style: const TextStyle(
                            color: ZenpexColors.offWhite,
                            fontSize: 28,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Receitas x Despesas do mês
              Row(
                children: [
                  Expanded(
                      child: _kpi('Receitas (mês)', receitas, ZenpexColors.ok)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _kpi(
                          'Despesas (mês)', despesas, const Color(0xFFE5484D))),
                ],
              ),
              const SizedBox(height: 20),
              if (d.alertas.temAlerta) ...[
                _sec('Alertas'),
                _alertasCard(d.alertas),
                const SizedBox(height: 20),
              ],
              _sec('Saldos por conta'),
              ...d.saldos.map(_contaTile),
              const SizedBox(height: 20),
              _sec('Despesas por categoria (mês)'),
              ...(d.categorias.where((c) => !c.isReceita).toList()
                    ..sort((a, b) => b.total.compareTo(a.total)))
                  .map((c) => _catTile(c, despesas)),
            ],
          ),
        );
      },
    );
  }

  Widget _kpi(String label, double v, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ZenpexColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZenpexColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: ZenpexColors.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(brMoney(v),
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _sec(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontFamily: monoFamily,
                fontFamilyFallback: monoFallback,
                fontSize: 12,
                letterSpacing: 1.2,
                color: ZenpexColors.textMuted)),
      );

  Widget _contaTile(SaldoConta c) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ZenpexColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ZenpexColors.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_outlined,
                color: ZenpexColors.lightBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.contaNome,
                      style: const TextStyle(
                          color: ZenpexColors.offWhite,
                          fontWeight: FontWeight.w600)),
                  Text(c.contaTipo,
                      style: const TextStyle(
                          color: ZenpexColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(brMoney(c.saldoAtual),
                style: TextStyle(
                    color: c.saldoAtual < 0
                        ? const Color(0xFFE5484D)
                        : ZenpexColors.offWhite,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _catTile(CategoriaResumo c, double total) {
    final frac = total > 0 ? (c.total / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZenpexColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZenpexColors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(c.categoriaNome,
                      style: const TextStyle(color: ZenpexColors.offWhite))),
              Text(brMoney(c.total),
                  style: const TextStyle(
                      color: ZenpexColors.offWhite,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 6,
              backgroundColor: ZenpexColors.outline,
              color: const Color(0xFFE5484D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertasCard(FinAlertas a) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2994A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFF2994A).withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.saldoNegativoEm != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFF2994A), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saldo pode ficar negativo em ${brDate(a.saldoNegativoEm)}',
                        style: const TextStyle(color: ZenpexColors.offWhite),
                      ),
                    ),
                  ],
                ),
              ),
            ...a.recorrenciasAVencer.map((r) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        r.tipo == 'RECEITA'
                            ? Icons.south_west
                            : Icons.north_east,
                        size: 16,
                        color: r.tipo == 'RECEITA'
                            ? ZenpexColors.ok
                            : const Color(0xFFE5484D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('${r.descricao} — ${brDate(r.dataPrevista)}',
                              style: const TextStyle(
                                  color: ZenpexColors.offWhite, fontSize: 13))),
                      Text(brMoney(r.valor),
                          style: const TextStyle(
                              color: ZenpexColors.textMuted, fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
      );
}

class _ResumoData {
  _ResumoData(
      {required this.saldos, required this.alertas, required this.categorias});
  final List<SaldoConta> saldos;
  final FinAlertas alertas;
  final List<CategoriaResumo> categorias;
}

class _LancamentosTab extends StatefulWidget {
  const _LancamentosTab({required this.repo});
  final FinanceiroRepository repo;
  @override
  State<_LancamentosTab> createState() => _LancamentosTabState();
}

class _LancamentosTabState extends State<_LancamentosTab> {
  late Future<List<Transacao>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Transacao>> _load() {
    final now = DateTime.now();
    return widget.repo.transacoes(
      inicio: DateTime(now.year, now.month, 1),
      fim: DateTime(now.year, now.month + 1, 0),
    );
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  Future<void> _abrirForm(BuildContext context, [Transacao? t]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TransacaoFormScreen(transacao: t)),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ZenpexColors.blue,
        foregroundColor: Colors.white,
        onPressed: () => _abrirForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: FutureBuilder<List<Transacao>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snap.hasError) {
            return ErrorRetry(
                message:
                    'Não foi possível carregar os lançamentos.\n${snap.error}',
                onRetry: _reload);
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'Nenhum lançamento no mês.');
          }
          return RefreshIndicator(
            onRefresh: _reload,
            color: ZenpexColors.blue,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _TransacaoTile(
                t: items[i],
                onTap: () => _abrirForm(context, items[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransacaoTile extends StatelessWidget {
  const _TransacaoTile({required this.t, required this.onTap});
  final Transacao t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor =
        t.isReceita ? ZenpexColors.ok : const Color(0xFFE5484D);
    return Material(
      color: ZenpexColors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ZenpexColors.outline),
          ),
          child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(t.isReceita ? Icons.south_west : Icons.north_east,
                color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.descricao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: ZenpexColors.offWhite,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  [
                    brDate(t.data),
                    if (t.categoriaNome != null) t.categoriaNome!,
                    if (t.status == 'PREVISTO') 'Previsto',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: ZenpexColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${t.isReceita ? '+' : '-'} ${brMoney(t.valor)}',
              style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelatoriosTab extends StatefulWidget {
  const _RelatoriosTab({required this.repo});
  final FinanceiroRepository repo;
  @override
  State<_RelatoriosTab> createState() => _RelatoriosTabState();
}

class _RelatoriosTabState extends State<_RelatoriosTab> {
  late DateTime _inicio;
  late DateTime _fim;
  late Future<Dre> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _inicio = DateTime(now.year, now.month, 1);
    _fim = DateTime(now.year, now.month + 1, 0);
    _future = widget.repo.dre(_inicio, _fim);
  }

  void _recarregar() =>
      setState(() => _future = widget.repo.dre(_inicio, _fim));

  Future<void> _pick(bool inicio) async {
    final d = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : _fim,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (inicio) {
        _inicio = d;
      } else {
        _fim = d;
      }
    });
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(child: _periodo('De', _inicio, () => _pick(true))),
              const SizedBox(width: 10),
              Expanded(child: _periodo('Até', _fim, () => _pick(false))),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Dre>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }
              if (snap.hasError) {
                return ErrorRetry(
                    message: 'Não foi possível gerar o DRE.\n${snap.error}',
                    onRetry: () async => _recarregar());
              }
              final d = snap.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _sec('DRE do período'),
                  _linha('Receita bruta', d.receitaBruta, sinal: '+'),
                  _linha('Impostos', d.impostos, sinal: '-'),
                  _linha('Lucro bruto', d.lucroBruto, total: true),
                  _linha('Despesas variáveis', d.despesasVariaveis, sinal: '-'),
                  _linha('Lucro operacional', d.lucroOperacional, total: true),
                  _linha('Despesas fixas', d.despesasFixas, sinal: '-'),
                  _linha('Gastos com pessoal', d.gastosPessoal, sinal: '-'),
                  const SizedBox(height: 8),
                  _resultado(d.resultadoExercicio),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _periodo(String label, DateTime value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: ZenpexColors.textMuted),
            filled: true,
            fillColor: ZenpexColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 15, color: ZenpexColors.textMuted),
              const SizedBox(width: 8),
              Text(brDate(value),
                  style: const TextStyle(color: ZenpexColors.offWhite)),
            ],
          ),
        ),
      );

  Widget _sec(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontFamily: monoFamily,
                fontFamilyFallback: monoFallback,
                fontSize: 12,
                letterSpacing: 1.2,
                color: ZenpexColors.textMuted)),
      );

  Widget _linha(String label, double valor, {String? sinal, bool total = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: total ? ZenpexColors.surfaceHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: total ? Border.all(color: ZenpexColors.outline) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: total ? ZenpexColors.offWhite : ZenpexColors.textMuted,
                  fontWeight: total ? FontWeight.w600 : FontWeight.w400,
                )),
          ),
          Text('${sinal ?? ''} ${brMoney(valor)}'.trim(),
              style: TextStyle(
                color: ZenpexColors.offWhite,
                fontWeight: total ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }

  Widget _resultado(double v) {
    final positivo = v >= 0;
    final cor = positivo ? ZenpexColors.ok : const Color(0xFFE5484D);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Resultado do exercício',
                style: TextStyle(
                    color: ZenpexColors.offWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
          Text(brMoney(v),
              style: TextStyle(
                  color: cor, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
