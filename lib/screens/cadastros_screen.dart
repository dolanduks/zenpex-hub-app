import 'package:flutter/material.dart';

import '../data/financeiro.dart';
import '../data/financeiro_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';
import '../widgets/states.dart';

const _contaTipos = ['CORRENTE', 'POUPANCA', 'CAIXA', 'INVESTIMENTO'];
const _contaTiposLabel = ['Corrente', 'Poupança', 'Caixa', 'Investimento'];
const _grupoDre = ['DESPESA_FIXA', 'DESPESA_VARIAVEL', 'IMPOSTO', 'PESSOAL'];
const _grupoDreLabel = ['Despesa fixa', 'Despesa variável', 'Imposto', 'Pessoal'];
const _contatoTipos = ['CLIENTE', 'FORNECEDOR', 'COLABORADOR', 'SOCIO', 'OUTRO'];
const _contatoTiposLabel = [
  'Cliente', 'Fornecedor', 'Colaborador', 'Sócio', 'Outro'
];

class CadastrosScreen extends StatelessWidget {
  const CadastrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = FinanceiroRepository();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ZenpexColors.surface,
          title: const Text('Cadastros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          bottom: const TabBar(
            labelColor: ZenpexColors.lightBlue,
            unselectedLabelColor: ZenpexColors.textMuted,
            indicatorColor: ZenpexColors.blue,
            tabs: [Tab(text: 'Contas'), Tab(text: 'Categorias'), Tab(text: 'Contatos')],
          ),
        ),
        body: TabBarView(
          children: [
            _ContasTab(repo: repo),
            _CategoriasTab(repo: repo),
            _ContatosTab(repo: repo),
          ],
        ),
      ),
    );
  }
}

// ----------------- Contas -----------------
class _ContasTab extends StatefulWidget {
  const _ContasTab({required this.repo});
  final FinanceiroRepository repo;
  @override
  State<_ContasTab> createState() => _ContasTabState();
}

class _ContasTabState extends State<_ContasTab> {
  late Future<List<FinConta>> _f;
  @override
  void initState() {
    super.initState();
    _f = widget.repo.contas();
  }

  Future<void> _reload() async => setState(() => _f = widget.repo.contas());

  Future<void> _form([FinConta? c]) async {
    final nome = TextEditingController(text: c?.nome ?? '');
    final banco = TextEditingController(text: c?.banco ?? '');
    final saldo = TextEditingController(
        text: c != null ? c.saldoInicial.toString() : '');
    var tipo = c?.tipo ?? 'CORRENTE';
    final ok = await _sheet(
      context,
      titulo: c == null ? 'Nova conta' : 'Editar conta',
      onDelete: c == null ? null : () => widget.repo.excluirConta(c.id),
      campos: (setS) => [
        _tf(nome, 'Nome', req: true),
        _tf(banco, 'Banco'),
        _dd('Tipo', tipo, _contaTipos, _contaTiposLabel,
            (v) => setS(() => tipo = v)),
        _tf(saldo, 'Saldo inicial', keyboard: TextInputType.number),
      ],
      salvar: () => widget.repo.salvarConta({
        'nome': nome.text.trim(),
        'banco': banco.text.trim().isEmpty ? null : banco.text.trim(),
        'tipo': tipo,
        'saldo_inicial':
            double.tryParse(saldo.text.replaceAll(',', '.')) ?? 0,
      }, id: c?.id),
      podeSalvar: () => nome.text.trim().isNotEmpty,
    );
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ListaScaffold<FinConta>(
      future: _f,
      onReload: _reload,
      onNovo: _form,
      vazio: 'Nenhuma conta cadastrada.',
      icone: Icons.account_balance_outlined,
      item: (c) => _tile(
        titulo: c.nome,
        sub: '${_contaTiposLabel[_contaTipos.indexOf(c.tipo)]}'
            '${c.banco != null ? ' · ${c.banco}' : ''}',
        trailing: brMoney(c.saldoInicial),
        onTap: () => _form(c),
      ),
    );
  }
}

// ----------------- Categorias -----------------
class _CategoriasTab extends StatefulWidget {
  const _CategoriasTab({required this.repo});
  final FinanceiroRepository repo;
  @override
  State<_CategoriasTab> createState() => _CategoriasTabState();
}

class _CategoriasTabState extends State<_CategoriasTab> {
  late Future<List<FinCategoria>> _f;
  @override
  void initState() {
    super.initState();
    _f = widget.repo.categorias();
  }

  Future<void> _reload() async => setState(() => _f = widget.repo.categorias());

  Future<void> _form([FinCategoria? c]) async {
    final nome = TextEditingController(text: c?.nome ?? '');
    var tipo = c?.tipo ?? 'DESPESA';
    String? grupo = c?.grupoDre;
    final ok = await _sheet(
      context,
      titulo: c == null ? 'Nova categoria' : 'Editar categoria',
      onDelete: c == null ? null : () => widget.repo.excluirCategoria(c.id),
      campos: (setS) => [
        _tf(nome, 'Nome', req: true),
        _dd('Tipo', tipo, const ['RECEITA', 'DESPESA'],
            const ['Receita', 'Despesa'], (v) => setS(() => tipo = v)),
        if (tipo == 'DESPESA')
          _ddNull('Grupo (DRE)', grupo, _grupoDre, _grupoDreLabel,
              (v) => setS(() => grupo = v)),
      ],
      salvar: () => widget.repo.salvarCategoria({
        'nome': nome.text.trim(),
        'tipo': tipo,
        'grupo_dre': tipo == 'DESPESA' ? grupo : null,
      }, id: c?.id),
      podeSalvar: () => nome.text.trim().isNotEmpty,
    );
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ListaScaffold<FinCategoria>(
      future: _f,
      onReload: _reload,
      onNovo: _form,
      vazio: 'Nenhuma categoria cadastrada.',
      icone: Icons.sell_outlined,
      item: (c) => _tile(
        titulo: c.nome,
        sub: c.isReceita ? 'Receita' : 'Despesa',
        trailingColor: c.isReceita ? ZenpexColors.ok : const Color(0xFFE5484D),
        trailing: c.isReceita ? 'Receita' : 'Despesa',
        onTap: () => _form(c),
      ),
    );
  }
}

// ----------------- Contatos -----------------
class _ContatosTab extends StatefulWidget {
  const _ContatosTab({required this.repo});
  final FinanceiroRepository repo;
  @override
  State<_ContatosTab> createState() => _ContatosTabState();
}

class _ContatosTabState extends State<_ContatosTab> {
  late Future<List<FinContato>> _f;
  @override
  void initState() {
    super.initState();
    _f = widget.repo.contatos();
  }

  Future<void> _reload() async => setState(() => _f = widget.repo.contatos());

  Future<void> _form([FinContato? c]) async {
    final nome = TextEditingController(text: c?.nome ?? '');
    final doc = TextEditingController(text: c?.documento ?? '');
    final email = TextEditingController(text: c?.email ?? '');
    final tel = TextEditingController(text: c?.telefone ?? '');
    var tipo = c?.tipo ?? 'OUTRO';
    final ok = await _sheet(
      context,
      titulo: c == null ? 'Novo contato' : 'Editar contato',
      onDelete: c == null ? null : () => widget.repo.excluirContato(c.id),
      campos: (setS) => [
        _tf(nome, 'Nome', req: true),
        _dd('Tipo', tipo, _contatoTipos, _contatoTiposLabel,
            (v) => setS(() => tipo = v)),
        _tf(doc, 'CNPJ / CPF'),
        _tf(email, 'E-mail', keyboard: TextInputType.emailAddress),
        _tf(tel, 'Telefone', keyboard: TextInputType.phone),
      ],
      salvar: () => widget.repo.salvarContato({
        'nome': nome.text.trim(),
        'tipo': tipo,
        'documento': doc.text.trim().isEmpty ? null : doc.text.trim(),
        'email': email.text.trim().isEmpty ? null : email.text.trim(),
        'telefone': tel.text.trim().isEmpty ? null : tel.text.trim(),
      }, id: c?.id),
      podeSalvar: () => nome.text.trim().isNotEmpty,
    );
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _ListaScaffold<FinContato>(
      future: _f,
      onReload: _reload,
      onNovo: _form,
      vazio: 'Nenhum contato cadastrado.',
      icone: Icons.contacts_outlined,
      item: (c) => _tile(
        titulo: c.nome,
        sub: _contatoTiposLabel[_contatoTipos.indexOf(c.tipo)] +
            (c.documento != null ? ' · ${c.documento}' : ''),
        onTap: () => _form(c),
      ),
    );
  }
}

// ----------------- helpers compartilhados -----------------
class _ListaScaffold<T> extends StatelessWidget {
  const _ListaScaffold({
    required this.future,
    required this.onReload,
    required this.onNovo,
    required this.item,
    required this.vazio,
    required this.icone,
  });
  final Future<List<T>> future;
  final Future<void> Function() onReload;
  final VoidCallback onNovo;
  final Widget Function(T) item;
  final String vazio;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: ZenpexColors.blue,
        foregroundColor: Colors.white,
        onPressed: onNovo,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<T>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snap.hasError) {
            return ErrorRetry(
                message: 'Não foi possível carregar.\n${snap.error}',
                onRetry: onReload);
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return EmptyState(icon: icone, message: vazio);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => item(items[i]),
          );
        },
      ),
    );
  }
}

Widget _tile({
  required String titulo,
  required String sub,
  String? trailing,
  Color? trailingColor,
  required VoidCallback onTap,
}) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: ZenpexColors.offWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: ZenpexColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing,
                  style: TextStyle(
                      color: trailingColor ?? ZenpexColors.offWhite,
                      fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}

Widget _tf(TextEditingController c, String label,
    {bool req = false, TextInputType? keyboard}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
      style: const TextStyle(color: ZenpexColors.offWhite),
      decoration: _dec(label),
    ),
  );
}

Widget _dd(String label, String value, List<String> vals, List<String> labels,
    ValueChanged<String> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: ZenpexColors.surfaceHigh,
      style: const TextStyle(color: ZenpexColors.offWhite),
      items: [
        for (var i = 0; i < vals.length; i++)
          DropdownMenuItem(value: vals[i], child: Text(labels[i])),
      ],
      onChanged: (v) => onChanged(v ?? value),
      decoration: _dec(label),
    ),
  );
}

Widget _ddNull(String label, String? value, List<String> vals,
    List<String> labels, ValueChanged<String?> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String?>(
      initialValue: value,
      dropdownColor: ZenpexColors.surfaceHigh,
      style: const TextStyle(color: ZenpexColors.offWhite),
      items: [
        const DropdownMenuItem(value: null, child: Text('—')),
        for (var i = 0; i < vals.length; i++)
          DropdownMenuItem(value: vals[i], child: Text(labels[i])),
      ],
      onChanged: onChanged,
      decoration: _dec(label),
    ),
  );
}

InputDecoration _dec(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: ZenpexColors.textMuted),
      filled: true,
      fillColor: ZenpexColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

/// Bottom sheet genérico de formulário (criar/editar + excluir).
Future<bool?> _sheet(
  BuildContext context, {
  required String titulo,
  required List<Widget> Function(StateSetter setS) campos,
  required Future<void> Function() salvar,
  required bool Function() podeSalvar,
  Future<void> Function()? onDelete,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ZenpexColors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      var saving = false;
      return StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(titulo,
                          style: const TextStyle(
                              color: ZenpexColors.offWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFEB6B4D)),
                        onPressed: saving
                            ? null
                            : () async {
                                setS(() => saving = true);
                                try {
                                  await onDelete();
                                  if (ctx.mounted) Navigator.pop(ctx, true);
                                } catch (_) {
                                  setS(() => saving = false);
                                }
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...campos(setS),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ZenpexColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    onPressed: saving || !podeSalvar()
                        ? null
                        : () async {
                            setS(() => saving = true);
                            try {
                              await salvar();
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              setS(() => saving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Erro ao salvar: $e')));
                            }
                          },
                    child: Text(saving ? 'Salvando…' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
