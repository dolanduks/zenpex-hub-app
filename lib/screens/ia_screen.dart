import 'package:flutter/material.dart';

import '../data/financeiro_repository.dart';
import '../theme.dart';

class _Msg {
  _Msg(this.texto, this.doUsuario);
  final String texto;
  final bool doUsuario;
}

class IaScreen extends StatefulWidget {
  const IaScreen({super.key});

  @override
  State<IaScreen> createState() => _IaScreenState();
}

class _IaScreenState extends State<IaScreen> {
  final _repo = FinanceiroRepository();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _add(_Msg m) {
    setState(() => _msgs.add(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _resumo() async {
    if (_busy) return;
    setState(() => _busy = true);
    _add(_Msg('Gerar resumo do mês', true));
    try {
      final r = await _repo.iaResumo();
      _add(_Msg(r, false));
    } catch (e) {
      _add(_Msg('Não foi possível gerar o resumo: $e', false));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _perguntar() async {
    final q = _input.text.trim();
    if (q.isEmpty || _busy) return;
    _input.clear();
    setState(() => _busy = true);
    _add(_Msg(q, true));
    try {
      final r = await _repo.iaPerguntar(q);
      _add(_Msg(r, false));
    } catch (e) {
      _add(_Msg('Não foi possível responder: $e', false));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('Assistente financeiro',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _msgs.isEmpty
                ? _vazio()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) => _bolha(_msgs[i]),
                  ),
          ),
          if (_busy) const LinearProgressIndicator(color: ZenpexColors.blue),
          _barra(),
        ],
      ),
    );
  }

  Widget _vazio() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 48, color: ZenpexColors.blue),
              const SizedBox(height: 16),
              const Text('Pergunte sobre as finanças da Zenpex',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: ZenpexColors.offWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'Ex.: "quanto gastei com fornecedores este mês?"\n'
                'A resposta é gerada por IA (Gemini) a partir dos lançamentos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ZenpexColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZenpexColors.lightBlue,
                  side: const BorderSide(color: ZenpexColors.blue),
                ),
                onPressed: _resumo,
                icon: const Icon(Icons.summarize_outlined),
                label: const Text('Resumo do mês'),
              ),
            ],
          ),
        ),
      );

  Widget _bolha(_Msg m) {
    return Align(
      alignment: m.doUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: m.doUsuario ? ZenpexColors.blue : ZenpexColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: m.doUsuario
              ? null
              : Border.all(color: ZenpexColors.outline),
        ),
        child: Text(
          m.texto,
          style: TextStyle(
            color: m.doUsuario ? Colors.white : ZenpexColors.offWhite,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _barra() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                style: const TextStyle(color: ZenpexColors.offWhite),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _perguntar(),
                decoration: InputDecoration(
                  hintText: 'Pergunte algo…',
                  hintStyle: const TextStyle(color: ZenpexColors.textMuted),
                  filled: true,
                  fillColor: ZenpexColors.surfaceHigh,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: ZenpexColors.blue,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _busy ? null : _perguntar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
