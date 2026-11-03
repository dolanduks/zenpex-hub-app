import 'package:flutter/material.dart';

import '../data/customers_repository.dart';
import '../data/license.dart';
import '../data/licenses_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';

class LicencaDetailScreen extends StatefulWidget {
  const LicencaDetailScreen({super.key, this.license});
  final License? license;

  @override
  State<LicencaDetailScreen> createState() => _LicencaDetailScreenState();
}

class _LicencaDetailScreenState extends State<LicencaDetailScreen> {
  final _repo = LicensesRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nome;
  late final TextEditingController _modelo;
  late final TextEditingController _descricao;
  late String _tipo;
  DateTime? _dataInicio;
  DateTime? _dataVencimento;
  int? _customerId;
  int? _categoryId;
  bool _saving = false;

  List<({int id, String nome})> _customers = [];
  List<({int id, String nome})> _categorias = [];
  bool _loadingOpts = true;

  bool get _isNew => widget.license == null;

  @override
  void initState() {
    super.initState();
    final l = widget.license;
    _nome = TextEditingController(text: l?.nomeProduto ?? '');
    _modelo = TextEditingController(text: l?.modelo ?? '');
    _descricao = TextEditingController(text: l?.descricao ?? '');
    _tipo = l?.tipo ?? 'CLIENTE';
    _dataInicio = l?.dataInicio;
    _dataVencimento = l?.dataVencimento;
    _customerId = l?.customerId;
    _categoryId = l?.categoryId;
    _loadOpts();
  }

  Future<void> _loadOpts() async {
    try {
      final cs = await CustomersRepository().list();
      final cats = await _repo.categorias();
      if (!mounted) return;
      setState(() {
        _customers =
            cs.map((c) => (id: c.id, nome: c.nome)).toList();
        _categorias = cats
            .map((e) => (id: e['id'] as int, nome: (e['nome'] ?? '') as String))
            .toList();
        _loadingOpts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOpts = false);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _modelo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  String? _iso(DateTime? d) =>
      d == null ? null : d.toIso8601String().split('T').first;

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2015),
        lastDate: DateTime(2100),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataVencimento == null) {
      _snack('Informe a data de vencimento.');
      return;
    }
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'nome_produto': _nome.text.trim(),
      'tipo': _tipo,
      'modelo': _modelo.text.trim().isEmpty ? null : _modelo.text.trim(),
      'descricao':
          _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
      'data_inicio': _iso(_dataInicio),
      'data_vencimento': _iso(_dataVencimento),
      'customer_id': _tipo == 'CLIENTE' ? _customerId : null,
      'category_id': _categoryId,
    };
    try {
      if (_isNew) {
        await _repo.create(payload);
      } else {
        await _repo.update(widget.license!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Erro ao salvar: $e');
    }
  }

  Future<void> _renovar() async {
    final nova = await _pickDate(_dataVencimento ?? DateTime.now());
    if (nova == null) return;
    setState(() => _saving = true);
    try {
      await _repo.renew(widget.license!.id, _iso(nova)!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Erro ao renovar: $e');
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZenpexColors.surfaceHigh,
        title: const Text('Excluir licença'),
        content: Text('Remover "${widget.license!.nomeProduto}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFE5484D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _repo.remove(widget.license!.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Erro ao excluir: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: Text(_isNew ? 'Nova licença' : 'Editar licença',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Renovar',
              icon: const Icon(Icons.event_repeat, color: ZenpexColors.ok),
              onPressed: _saving ? null : _renovar,
            ),
          if (!_isNew)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEB6B4D)),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: _loadingOpts
          ? const Center(
              child: CircularProgressIndicator(color: ZenpexColors.blue))
          : AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _textField(_nome, 'Produto', required: true),
                    _dropdown<String>(
                      label: 'Tipo',
                      value: _tipo,
                      items: const [
                        DropdownMenuItem(
                            value: 'CLIENTE', child: Text('Cliente')),
                        DropdownMenuItem(
                            value: 'INTERNO', child: Text('Interno')),
                      ],
                      onChanged: (v) => setState(() => _tipo = v ?? 'CLIENTE'),
                    ),
                    if (_tipo == 'CLIENTE')
                      _dropdown<int?>(
                        label: 'Cliente',
                        value: _customerId,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('—')),
                          ..._customers.map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.nome))),
                        ],
                        onChanged: (v) => setState(() => _customerId = v),
                      ),
                    _dropdown<int?>(
                      label: 'Categoria',
                      value: _categoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ..._categorias.map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.nome))),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    _textField(_modelo, 'Modelo / plano'),
                    _textField(_descricao, 'Descrição', maxLines: 2),
                    _dateField('Início', _dataInicio,
                        (d) => setState(() => _dataInicio = d)),
                    _dateField('Vencimento', _dataVencimento,
                        (d) => setState(() => _dataVencimento = d)),
                    const SizedBox(height: 24),
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

  Widget _textField(TextEditingController c, String label,
      {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: ZenpexColors.offWhite),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
            : null,
        decoration: _dec(label),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: ZenpexColors.surfaceHigh,
        style: const TextStyle(color: ZenpexColors.offWhite),
        decoration: _dec(label),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime> onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () async {
          final d = await _pickDate(value);
          if (d != null) onPick(d);
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _dec(label),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: ZenpexColors.textMuted),
              const SizedBox(width: 10),
              Text(
                value == null ? 'Selecionar' : brDate(value),
                style: TextStyle(
                  color: value == null
                      ? ZenpexColors.textMuted
                      : ZenpexColors.offWhite,
                ),
              ),
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
