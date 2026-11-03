import 'package:flutter/material.dart';

import '../data/customer.dart';
import '../data/customers_repository.dart';
import '../theme.dart';

/// Detalhe/edição de cliente. Sem [customer] = criação de novo.
class ClienteDetailScreen extends StatefulWidget {
  const ClienteDetailScreen({super.key, this.customer});
  final Customer? customer;

  @override
  State<ClienteDetailScreen> createState() => _ClienteDetailScreenState();
}

class _ClienteDetailScreenState extends State<ClienteDetailScreen> {
  final _repo = CustomersRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nome;
  late final TextEditingController _documento;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _horas;
  late bool _ativo;
  bool _saving = false;

  bool get _isNew => widget.customer == null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nome = TextEditingController(text: c?.nome ?? '');
    _documento = TextEditingController(text: c?.documento ?? '');
    _email = TextEditingController(text: c?.emailContato ?? '');
    _telefone = TextEditingController(text: c?.telefone ?? '');
    _horas = TextEditingController(
      text: c?.horasContratadasMensais?.toString() ?? '',
    );
    _ativo = c?.isAtivo ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _documento.dispose();
    _email.dispose();
    _telefone.dispose();
    _horas.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'nome': _nome.text.trim(),
      'documento': _nullIfEmpty(_documento.text),
      'email_contato': _nullIfEmpty(_email.text),
      'telefone': _nullIfEmpty(_telefone.text),
      'horas_contratadas_mensais': double.tryParse(_horas.text.replaceAll(',', '.')),
    };
    try {
      if (_isNew) {
        await _repo.create(payload);
      } else {
        payload['is_ativo'] = _ativo;
        await _repo.update(widget.customer!.id, payload);
      }
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
        title: const Text('Excluir cliente'),
        content: Text('Remover "${widget.customer!.nome}"? Isso não pode ser desfeito.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE5484D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _repo.remove(widget.customer!.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Erro ao excluir: $e');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: Text(
          _isNew ? 'Novo cliente' : 'Editar cliente',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEB6B4D)),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _field(_nome, 'Nome', required: true),
              _field(_documento, 'CNPJ / CPF'),
              _field(_email, 'E-mail de contato',
                  keyboard: TextInputType.emailAddress),
              _field(_telefone, 'Telefone', keyboard: TextInputType.phone),
              _field(_horas, 'Horas contratadas/mês',
                  keyboard: TextInputType.number),
              if (!_isNew)
                SwitchListTile(
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                  activeThumbColor: ZenpexColors.blue,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cliente ativo',
                      style: TextStyle(color: ZenpexColors.offWhite)),
                ),
              if (!_isNew && widget.customer!.isMilvus)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Cliente sincronizado do Milvus. Alterações aqui não são '
                    'sobrescritas pela sincronização.',
                    style: TextStyle(fontSize: 12, color: ZenpexColors.textMuted),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ZenpexColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
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

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(color: ZenpexColors.offWhite),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
            : null,
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
      ),
    );
  }
}
