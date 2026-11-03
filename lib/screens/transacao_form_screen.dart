import 'package:flutter/material.dart';

import '../data/financeiro.dart';
import '../data/financeiro_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';

class TransacaoFormScreen extends StatefulWidget {
  const TransacaoFormScreen({super.key, this.transacao});
  final Transacao? transacao;

  @override
  State<TransacaoFormScreen> createState() => _TransacaoFormScreenState();
}

class _TransacaoFormScreenState extends State<TransacaoFormScreen> {
  final _repo = FinanceiroRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descricao;
  late final TextEditingController _valor;
  late final TextEditingController _obs;
  late String _tipo;
  late DateTime _data;
  int? _contaId;
  int? _categoriaId;
  int? _contatoId;

  List<FinConta> _contas = [];
  List<FinCategoria> _categorias = [];
  List<FinContato> _contatos = [];
  bool _loading = true;
  bool _saving = false;

  bool get _isNew => widget.transacao == null;

  @override
  void initState() {
    super.initState();
    final t = widget.transacao;
    _descricao = TextEditingController(text: t?.descricao ?? '');
    _valor = TextEditingController(text: t != null ? t.valor.toString() : '');
    _obs = TextEditingController(text: t?.observacoes ?? '');
    _tipo = t?.tipo ?? 'DESPESA';
    _data = t?.data ?? DateTime.now();
    _contaId = t?.contaBancariaId;
    _categoriaId = t?.categoriaId;
    _contatoId = t?.contatoId;
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _repo.contas();
      final cat = await _repo.categorias();
      final con = await _repo.contatos();
      if (!mounted) return;
      setState(() {
        _contas = c;
        _categorias = cat;
        _contatos = con;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contaId == null) {
      _snack('Selecione a conta.');
      return;
    }
    final valor = double.tryParse(_valor.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      _snack('Informe um valor válido.');
      return;
    }
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'conta_bancaria_id': _contaId,
      'categoria_id': _categoriaId,
      'contato_id': _contatoId,
      'descricao': _descricao.text.trim(),
      'tipo': _tipo,
      'valor': valor,
      'data': _data.toIso8601String().split('T').first,
      'observacoes': _obs.text.trim().isEmpty ? null : _obs.text.trim(),
    };
    try {
      await _repo.salvarTransacao(payload, id: widget.transacao?.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Erro ao salvar: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    // Categorias compatíveis com o tipo selecionado.
    final cats = _categorias.where((c) => c.tipo == _tipo).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: Text(_isNew ? 'Novo lançamento' : 'Editar lançamento',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ZenpexColors.blue))
          : AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // Tipo (receita/despesa)
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'RECEITA',
                            label: Text('Receita'),
                            icon: Icon(Icons.south_west)),
                        ButtonSegment(
                            value: 'DESPESA',
                            label: Text('Despesa'),
                            icon: Icon(Icons.north_east)),
                      ],
                      selected: {_tipo},
                      onSelectionChanged: (s) => setState(() {
                        _tipo = s.first;
                        _categoriaId = null; // reseta categoria ao trocar tipo
                      }),
                    ),
                    const SizedBox(height: 16),
                    _tf(_valor, 'Valor', keyboard: TextInputType.number),
                    _tf(_descricao, 'Descrição', req: true),
                    _dateField(),
                    _dd<int?>(
                      'Conta',
                      _contaId,
                      [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ..._contas.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.nome))),
                      ],
                      (v) => setState(() => _contaId = v),
                    ),
                    _dd<int?>(
                      'Categoria',
                      cats.any((c) => c.id == _categoriaId) ? _categoriaId : null,
                      [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...cats.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.nome))),
                      ],
                      (v) => setState(() => _categoriaId = v),
                    ),
                    _dd<int?>(
                      'Contato',
                      _contatoId,
                      [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ..._contatos.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.nome))),
                      ],
                      (v) => setState(() => _contatoId = v),
                    ),
                    _tf(_obs, 'Observações', maxLines: 2),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: ZenpexColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Icon(Icons.check),
                        label: Text(_saving ? 'Salvando…' : 'Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _tf(TextEditingController c, String label,
      {bool req = false, int maxLines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(color: ZenpexColors.offWhite),
        validator: req
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
            : null,
        decoration: _dec(label),
      ),
    );
  }

  Widget _dd<T>(String label, T value, List<DropdownMenuItem<T>> items,
      ValueChanged<T?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
        dropdownColor: ZenpexColors.surfaceHigh,
        style: const TextStyle(color: ZenpexColors.offWhite),
        decoration: _dec(label),
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: _data,
            firstDate: DateTime(2015),
            lastDate: DateTime(2100),
          );
          if (d != null) setState(() => _data = d);
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _dec('Data'),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: ZenpexColors.textMuted),
              const SizedBox(width: 10),
              Text(brDate(_data),
                  style: const TextStyle(color: ZenpexColors.offWhite)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ZenpexColors.textMuted),
        filled: true,
        fillColor: ZenpexColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}
