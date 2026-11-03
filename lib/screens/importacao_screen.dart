import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/financeiro.dart';
import '../data/financeiro_repository.dart';
import '../theme.dart';

class ImportacaoScreen extends StatefulWidget {
  const ImportacaoScreen({super.key});

  @override
  State<ImportacaoScreen> createState() => _ImportacaoScreenState();
}

class _ImportacaoScreenState extends State<ImportacaoScreen> {
  final _repo = FinanceiroRepository();
  List<FinConta> _contas = [];
  int? _contaId;
  bool _loading = true;
  bool _enviando = false;
  Map<String, dynamic>? _resultado;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _repo.contas();
      if (!mounted) return;
      setState(() {
        _contas = c;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importar(bool ofx) async {
    if (_contaId == null) {
      _snack('Selecione a conta de destino.');
      return;
    }
    String? path;
    if (AppConfig.devPreview) {
      path = 'preview.${ofx ? 'ofx' : 'xlsx'}';
    } else {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ofx ? ['ofx'] : ['xlsx', 'xls'],
      );
      path = res?.files.single.path;
      if (path == null) return;
    }
    setState(() {
      _enviando = true;
      _resultado = null;
    });
    try {
      final r = await _repo.importar(ofx: ofx, contaId: _contaId!, filePath: path);
      if (!mounted) return;
      setState(() => _resultado = r);
    } catch (e) {
      if (!mounted) return;
      _snack('Erro na importação: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('Importar extrato',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ZenpexColors.blue))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const Text(
                  'Importe o extrato bancário (OFX) ou uma planilha (Excel) '
                  'para lançar as movimentações automaticamente.',
                  style: TextStyle(color: ZenpexColors.textMuted),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _contaId,
                  isExpanded: true,
                  dropdownColor: ZenpexColors.surfaceHigh,
                  style: const TextStyle(color: ZenpexColors.offWhite),
                  hint: const Text('Conta de destino',
                      style: TextStyle(color: ZenpexColors.textMuted)),
                  items: _contas
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nome)))
                      .toList(),
                  onChanged: (v) => setState(() => _contaId = v),
                  decoration: _dec('Conta'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _botao('Arquivo OFX', Icons.account_balance,
                          () => _importar(true)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _botao('Planilha Excel', Icons.table_chart,
                          () => _importar(false)),
                    ),
                  ],
                ),
                if (_enviando) ...[
                  const SizedBox(height: 24),
                  const Center(
                      child:
                          CircularProgressIndicator(color: ZenpexColors.blue)),
                  const SizedBox(height: 8),
                  const Center(
                      child: Text('Importando…',
                          style: TextStyle(color: ZenpexColors.textMuted))),
                ],
                if (_resultado != null) ...[
                  const SizedBox(height: 24),
                  _resultadoCard(_resultado!),
                ],
              ],
            ),
    );
  }

  Widget _botao(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 96,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: ZenpexColors.surfaceHigh,
          foregroundColor: ZenpexColors.offWhite,
          side: const BorderSide(color: ZenpexColors.outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _enviando ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ZenpexColors.lightBlue, size: 28),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _resultadoCard(Map<String, dynamic> r) {
    int v(String k) => (r[k] as num?)?.toInt() ?? 0;
    final erro = r['erro'] as String?;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZenpexColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZenpexColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resultado da importação',
              style: TextStyle(
                  color: ZenpexColors.offWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _linha('Importadas', v('total_importadas'), ZenpexColors.ok),
          _linha('Duplicadas (ignoradas)', v('total_duplicadas'),
              ZenpexColors.textMuted),
          _linha('Erros', v('total_erros'), const Color(0xFFE5484D)),
          if (r['total_no_arquivo'] != null)
            _linha('Total no arquivo', v('total_no_arquivo'),
                ZenpexColors.lightBlue),
          if (erro != null) ...[
            const SizedBox(height: 8),
            Text(erro, style: const TextStyle(color: Color(0xFFEB6B4D))),
          ],
        ],
      ),
    );
  }

  Widget _linha(String label, int valor, Color cor) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(color: ZenpexColors.textMuted))),
            Text('$valor',
                style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
          ],
        ),
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
