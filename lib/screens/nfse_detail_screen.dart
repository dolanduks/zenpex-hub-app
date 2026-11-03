import 'package:flutter/material.dart';

import '../data/nfse.dart';
import '../data/nfse_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';
import 'nfse_screen.dart' show nfseBadge;

class NfseDetailScreen extends StatefulWidget {
  const NfseDetailScreen({super.key, required this.nfse});
  final Nfse nfse;

  @override
  State<NfseDetailScreen> createState() => _NfseDetailScreenState();
}

class _NfseDetailScreenState extends State<NfseDetailScreen> {
  final _repo = NfseRepository();
  late Nfse _n;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _n = widget.nfse;
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() action, String erroMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('$erroMsg: $e');
    }
  }

  Future<void> _emitir() async {
    final ok = await _confirm('Emitir nota',
        'Enviar esta nota para a prefeitura? Essa ação é definitiva.');
    if (ok) _run(() => _repo.emitir(_n.id), 'Erro ao emitir');
  }

  Future<void> _descartar() async {
    final ok = await _confirm('Descartar rascunho',
        'Remover este rascunho? Isso não pode ser desfeito.');
    if (ok) _run(() => _repo.descartar(_n.id), 'Erro ao descartar');
  }

  Future<void> _reenviar() => _run(
      () => _repo.reenviarEmail(_n.id), 'Erro ao reenviar e-mail');

  Future<void> _cancelar() async {
    int codigo = 1;
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: ZenpexColors.surfaceHigh,
          title: const Text('Cancelar nota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: codigo,
                dropdownColor: ZenpexColors.surfaceHigh,
                style: const TextStyle(color: ZenpexColors.offWhite),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Erro na emissão')),
                  DropdownMenuItem(value: 2, child: Text('Serviço não prestado')),
                  DropdownMenuItem(value: 9, child: Text('Outros')),
                ],
                onChanged: (v) => setD(() => codigo = v ?? 1),
                decoration: const InputDecoration(labelText: 'Motivo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoCtrl,
                style: const TextStyle(color: ZenpexColors.offWhite),
                decoration: const InputDecoration(
                    labelText: 'Descrição do motivo'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Voltar')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE5484D)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancelar nota'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      _run(() => _repo.cancelar(_n.id, codigo, motivoCtrl.text.trim()),
          'Erro ao cancelar');
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZenpexColors.surfaceHigh,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Voltar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ZenpexColors.blue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    final b = nfseBadge(_n.status);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('Nota fiscal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_n.clienteNome ?? 'Cliente',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ZenpexColors.offWhite)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: b.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(b.label,
                      style: TextStyle(
                          color: b.color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(brMoney(_n.valorServico),
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: ZenpexColors.lightBlue)),
            const SizedBox(height: 20),
            if (_n.status == 'REJEITADA' && _n.mensagemErro != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5484D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE5484D).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFE5484D), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_n.mensagemErro!,
                          style:
                              const TextStyle(color: ZenpexColors.offWhite)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _info('Descrição', _n.descricao),
            _info('Competência', brDate(_n.competencia)),
            if (_n.numeroNfse != null) _info('Número', _n.numeroNfse!),
            if (_n.chaveAcesso != null) _info('Chave de acesso', _n.chaveAcesso!),
            if (_n.emitidaEm != null) _info('Emitida em', brDate(_n.emitidaEm)),
            if (_n.emailEnviadoEm != null)
              _info('E-mail enviado',
                  '${brDate(_n.emailEnviadoEm)} — ${_n.emailDestinatarios ?? ''}'),
            const SizedBox(height: 24),
            ..._acoes(),
          ],
        ),
      ),
    );
  }

  List<Widget> _acoes() {
    if (_n.isRascunho) {
      return [
        _btn('Emitir nota', Icons.send, ZenpexColors.blue, _emitir),
        const SizedBox(height: 10),
        _btn('Descartar', Icons.delete_outline, const Color(0xFFE5484D),
            _descartar,
            outlined: true),
      ];
    }
    if (_n.isEmitida) {
      return [
        _btn('Reenviar por e-mail', Icons.email_outlined, ZenpexColors.blue,
            _reenviar),
        const SizedBox(height: 10),
        _btn('Cancelar nota', Icons.cancel_outlined, const Color(0xFFE5484D),
            _cancelar,
            outlined: true),
      ];
    }
    return [];
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap,
      {bool outlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              onPressed: _busy ? null : onTap,
              icon: Icon(icon),
              label: Text(label),
            )
          : FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              onPressed: _busy ? null : onTap,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: ZenpexColors.textMuted, fontSize: 12)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(color: ZenpexColors.offWhite, fontSize: 15)),
          ],
        ),
      );
}
