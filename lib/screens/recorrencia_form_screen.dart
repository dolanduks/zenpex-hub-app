import 'package:flutter/material.dart';

import '../data/financeiro.dart';
import '../data/financeiro_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';

class RecorrenciaFormScreen extends StatefulWidget {
  const RecorrenciaFormScreen({super.key, this.recorrencia});
  final FinRecorrencia? recorrencia;

  @override
  State<RecorrenciaFormScreen> createState() => _RecorrenciaFormScreenState();
}

class _RecorrenciaFormScreenState extends State<RecorrenciaFormScreen> {
  final _repo = FinanceiroRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descricao;
  late final TextEditingController _valor;
  late final TextEditingController _diaMes;
  late String _tipo;
  late String _freq;
  late DateTime _dataInicio;
  DateTime? _dataFim;
  int? _contaId;
  int? _categoriaId;
  int? _contatoId;

  List<FinConta> _contas = [];
  List<FinCategoria> _categorias = [];
  List<FinContato> _contatos = [];
  bool _loading = true;
  bool _saving = false;

  bool get _isNew => widget.recorrencia == null;

  @override
  void initState() {
    super.initState();
    final r = widget.recorrencia;
    _descricao = TextEditingController(text: r?.descricao ?? '');
    _valor = TextEditingController(text: r != null ? r.valor.toString() : '');
    _diaMes =
        TextEditingController(text: r?.diaDoMes != null ? '${r!.diaDoMes}' : '');
    _tipo = r?.tipo ?? 'DESPESA';
    _freq = r?.frequencia ?? 'MENSAL';
    _dataInicio = r?.dataInicio ?? DateTime.now();
    _dataFim = r?.dataFim;
    _contaId = r?.contaBancariaId;
    _categoriaId = r?.categoriaId;
    _contatoId = r?.contatoId;
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
    _diaMes.dispose();
    super.dispose();
  }

  String _iso(DateTime d) => d.toIso8601String().split('T').first;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contaId == null) return _snack('Selecione a conta.');
    final valor = double.tryParse(_valor.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) return _snack('Informe um valor válido.');
    final precisaDia = _freq == 'MENSAL' || _freq == 'ANUAL';
    final dia = int.tryParse(_diaMes.text);
    if (precisaDia && (dia == null || dia < 1 || dia > 31)) {
      return _snack('Informe o dia do mês (1–31).');
    }
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'conta_bancaria_id': _contaId,
      'categoria_id': _categoriaId,
      'contato_id': _contatoId,
      'descricao': _descricao.text.trim(),
      'tipo': _tipo,
      'valor': valor,
      'frequencia': _freq,
      'dia_do_mes': precisaDia ? dia : null,
      'data_inicio': _iso(_dataInicio),
      'data_fim': _dataFim != null ? _iso(_dataFim!) : null,
    };
    try {
      await _repo.salvarRecorrencia(payload, id: widget.recorrencia?.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Erro ao salvar: $e');
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZenpexColors.surfaceHigh,
        title: const Text('Excluir recorrência'),
        content: Text('Remover "${widget.recorrencia!.descricao}"?'),
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
      await _repo.excluirRecorrencia(widget.recorrencia!.id);
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
    final cats = _categorias.where((c) => c.tipo == _tipo).toList();
    final precisaDia = _freq == 'MENSAL' || _freq == 'ANUAL';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: Text(_isNew ? 'Nova recorrência' : 'Editar recorrência',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEB6B4D)),
              onPressed: _saving ? null : _delete,
            ),
        ],
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
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'RECEITA', label: Text('Receita')),
                        ButtonSegment(value: 'DESPESA', label: Text('Despesa')),
                      ],
                      selected: {_tipo},
                      onSelectionChanged: (s) => setState(() {
                        _tipo = s.first;
                        _categoriaId = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    _tf(_descricao, 'Descrição', req: true),
                    _tf(_valor, 'Valor', keyboard: TextInputType.number),
                    _dd<String>('Frequência', _freq, const [
                      DropdownMenuItem(value: 'SEMANAL', child: Text('Semanal')),
                      DropdownMenuItem(value: 'MENSAL', child: Text('Mensal')),
                      DropdownMenuItem(value: 'ANUAL', child: Text('Anual')),
                    ], (v) => setState(() => _freq = v ?? 'MENSAL')),
                    if (precisaDia)
                      _tf(_diaMes, 'Dia do mês (1–31)',
                          keyboard: TextInputType.number),
                    _dateField('Início', _dataInicio,
                        (d) => setState(() => _dataInicio = d)),
                    _dateFieldNull('Fim (opcional)', _dataFim,
                        (d) => setState(() => _dataFim = d)),
                    _dd<int?>('Conta', _contaId, [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ..._contas.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nome))),
                    ], (v) => setState(() => _contaId = v)),
                    _dd<int?>(
                        'Categoria',
                        cats.any((c) => c.id == _categoriaId)
                            ? _categoriaId
                            : null, [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ...cats.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nome))),
                    ], (v) => setState(() => _categoriaId = v)),
                    _dd<int?>('Contato', _contatoId, [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ..._contatos.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nome))),
                    ], (v) => setState(() => _contatoId = v)),
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
      {bool req = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
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

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onPick) {
    return _dateBase(label, brDate(value), () async {
      final d = await _pick(value);
      if (d != null) onPick(d);
    });
  }

  Widget _dateFieldNull(
      String label, DateTime? value, ValueChanged<DateTime> onPick) {
    return _dateBase(label, value == null ? 'Selecionar' : brDate(value),
        () async {
      final d = await _pick(value ?? DateTime.now());
      if (d != null) onPick(d);
    });
  }

  Widget _dateBase(String label, String texto, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _dec(label),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: ZenpexColors.textMuted),
              const SizedBox(width: 10),
              Text(texto, style: const TextStyle(color: ZenpexColors.offWhite)),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2015),
        lastDate: DateTime(2100),
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
      );
}
