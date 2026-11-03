import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/chamado.dart';
import '../data/customer.dart';
import '../data/customers_repository.dart';
import '../data/milvus_repository.dart';
import '../data/projeto.dart';
import '../data/projetos_repository.dart';
import '../theme.dart';
import '../widgets/format.dart';

const _mesesCurto = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

class ProjetoFormScreen extends StatefulWidget {
  const ProjetoFormScreen({super.key, this.projeto});
  final Projeto? projeto;

  @override
  State<ProjetoFormScreen> createState() => _ProjetoFormScreenState();
}

class _ProjetoFormScreenState extends State<ProjetoFormScreen> {
  final _repo = ProjetosRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late final TextEditingController _contato;
  late final TextEditingController _valor;
  late final TextEditingController _horas;
  int? _clienteId;
  int? _servicoId;
  DateTime? _data;

  int? _projetoId; // id do projeto salvo (para anexos)
  List<Customer> _clientes = [];
  List<ProjetoServico> _servicos = [];
  List<ProjetoAnexo> _anexos = [];
  bool _loading = true;
  bool _saving = false;
  bool _enviandoAnexo = false;

  // Seletor de chamados do Milvus (auto-horas).
  final _milvus = MilvusRepository();
  late int _chamMes;
  late int _chamAno;
  List<Chamado> _chamLista = [];
  final Set<int> _chamSel = {};
  final Set<int> _chamJaVinc = {};
  bool _chamBuscando = false;
  String? _chamErro;

  bool get _isNew => _projetoId == null;

  @override
  void initState() {
    super.initState();
    final p = widget.projeto;
    _projetoId = p?.id;
    _nome = TextEditingController(text: p?.nome ?? '');
    _descricao = TextEditingController(text: p?.descricao ?? '');
    _contato = TextEditingController(text: p?.contatoCliente ?? '');
    _valor = TextEditingController(
        text: p?.valor != null ? p!.valor.toString().replaceAll('.', ',') : '');
    _horas = TextEditingController(
        text: p?.horas != null ? p!.horas.toString().replaceAll('.', ',') : '');
    _clienteId = p?.customerId;
    _servicoId = p?.servicoId;
    _data = p?.data;
    final agora = DateTime.now();
    _chamMes = agora.month;
    _chamAno = agora.year;
    _load();
  }

  Future<void> _load() async {
    try {
      final clientes = await CustomersRepository().list();
      final servicos = await _repo.servicos();
      List<ProjetoAnexo> anexos = [];
      if (_projetoId != null) {
        final detalhe = await _repo.detalhe(_projetoId!);
        anexos = detalhe.anexos;
        for (final c in detalhe.chamados) {
          _chamJaVinc.add(c.chamadoCodigo);
          _chamSel.add(c.chamadoCodigo);
        }
      }
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _servicos = servicos;
        _anexos = anexos;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buscarChamados() async {
    if (_clienteId == null) {
      setState(() => _chamErro = 'Selecione o cliente primeiro.');
      return;
    }
    setState(() {
      _chamBuscando = true;
      _chamErro = null;
    });
    try {
      final rep = await _milvus.chamados(_clienteId!, _chamAno, _chamMes);
      if (!mounted) return;
      setState(() {
        _chamLista = rep.finalizadosOperadores;
        _chamBuscando = false;
        if (_chamLista.isEmpty) {
          _chamErro = 'Nenhum chamado de Pedro/Marco no período.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chamBuscando = false;
        _chamErro = 'Erro ao buscar: $e';
      });
    }
  }

  void _toggleChamado(int codigo) {
    setState(() {
      if (_chamSel.contains(codigo)) {
        _chamSel.remove(codigo);
      } else {
        _chamSel.add(codigo);
      }
      final soma = _chamLista
          .where((c) => c.codigo != null && _chamSel.contains(c.codigo))
          .fold<double>(0, (acc, c) => acc + c.horasDecimal);
      if (soma > 0) {
        _horas.text = _numToText(soma);
      }
    });
  }

  String _numToText(double v) {
    final s = (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return s.replaceAll('.', ',');
  }

  Future<void> _vincularSelecionados(int projetoId) async {
    for (final codigo in _chamSel) {
      if (_chamJaVinc.contains(codigo)) continue;
      await _repo.vincularChamado(projetoId, codigo, _clienteId);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _contato.dispose();
    _valor.dispose();
    _horas.dispose();
    super.dispose();
  }

  double? _num(String s) {
    final limpo = s.trim().replaceAll('.', '').replaceAll(',', '.');
    if (limpo.isEmpty) return null;
    return double.tryParse(limpo);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteId == null) {
      _snack('Selecione o cliente.');
      return;
    }
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'customer_id': _clienteId,
      'servico_id': _servicoId,
      'nome': _nome.text.trim(),
      'descricao': _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
      'valor': _num(_valor.text),
      'horas': _num(_horas.text),
      'contato_cliente': _contato.text.trim().isEmpty ? null : _contato.text.trim(),
      'data': _data?.toIso8601String().split('T').first,
    };
    final eraNovo = _isNew;
    try {
      final p = await _repo.salvar(payload, id: _projetoId);
      await _vincularSelecionados(p.id);
      _chamJaVinc
        ..clear()
        ..addAll(_chamSel);
      if (!mounted) return;
      if (eraNovo) {
        // Fica no formulário (agora em modo edição) para permitir anexar documentos.
        setState(() {
          _projetoId = p.id;
          _saving = false;
        });
        _snack('Projeto criado. Agora você pode anexar documentos.');
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Erro ao salvar: $e');
    }
  }

  Future<void> _cadastrarServico() async {
    final ctrl = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZenpexColors.surfaceHigh,
        title: const Text('Novo serviço',
            style: TextStyle(color: ZenpexColors.offWhite)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: ZenpexColors.offWhite),
          decoration: _dec('Nome do serviço'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ZenpexColors.blue),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (nome == null || nome.isEmpty) return;
    try {
      final s = await _repo.criarServico(nome);
      if (!mounted) return;
      setState(() {
        if (!_servicos.any((x) => x.id == s.id)) _servicos.add(s);
        _servicoId = s.id;
      });
    } catch (e) {
      _snack('Erro ao cadastrar serviço: $e');
    }
  }

  Future<void> _anexar() async {
    if (_projetoId == null) return;
    final res = await FilePicker.platform.pickFiles();
    final path = res?.files.single.path;
    if (path == null) return;
    setState(() => _enviandoAnexo = true);
    try {
      final anexo = await _repo.enviarAnexo(_projetoId!, path);
      if (!mounted) return;
      setState(() {
        _anexos.add(anexo);
        _enviandoAnexo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviandoAnexo = false);
      _snack('Erro ao anexar: $e');
    }
  }

  Future<void> _removerAnexo(ProjetoAnexo a) async {
    try {
      await _repo.excluirAnexo(a.id);
      if (!mounted) return;
      setState(() => _anexos.removeWhere((x) => x.id == a.id));
    } catch (e) {
      _snack('Erro ao remover: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: Text(widget.projeto == null && _isNew ? 'Novo projeto' : 'Editar projeto',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ZenpexColors.blue))
          : AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _dd<int?>(
                      'Cliente *',
                      _clientes.any((c) => c.id == _clienteId) ? _clienteId : null,
                      [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ..._clientes.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.nome))),
                      ],
                      (v) => setState(() => _clienteId = v),
                    ),
                    _tf(_nome, 'Nome do projeto', req: true),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _dd<int?>(
                            'Serviço',
                            _servicos.any((s) => s.id == _servicoId) ? _servicoId : null,
                            [
                              const DropdownMenuItem(value: null, child: Text('—')),
                              ..._servicos.map((s) =>
                                  DropdownMenuItem(value: s.id, child: Text(s.nome))),
                            ],
                            (v) => setState(() => _servicoId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: IconButton(
                            onPressed: _cadastrarServico,
                            icon: const Icon(Icons.add_circle_outline,
                                color: ZenpexColors.blue),
                            tooltip: 'Cadastrar serviço',
                          ),
                        ),
                      ],
                    ),
                    _tf(_contato, 'Contato do cliente'),
                    Row(
                      children: [
                        Expanded(
                            child: _tf(_valor, 'Valor (R\$)',
                                keyboard: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _tf(_horas, 'Horas',
                                keyboard: TextInputType.number)),
                      ],
                    ),
                    _dateField(),
                    _tf(_descricao, 'Descrição', maxLines: 3),
                    if (_clienteId != null) _secChamados(),
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
                        label: Text(_saving
                            ? 'Salvando…'
                            : _isNew
                                ? 'Criar projeto'
                                : 'Salvar alterações'),
                      ),
                    ),
                    if (_isNew)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Salve o projeto para poder anexar documentos.',
                            style: TextStyle(
                                color: ZenpexColors.textMuted, fontSize: 12)),
                      ),
                    if (!_isNew) _secAnexos(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _secChamados() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ZenpexColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZenpexColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Incluir chamados do Milvus (opcional)',
                style: TextStyle(
                    color: ZenpexColors.offWhite, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Marque os chamados do projeto — as horas são somadas sozinhas no campo Horas.',
              style: TextStyle(color: ZenpexColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _chamMes,
                    isExpanded: true,
                    dropdownColor: ZenpexColors.surface,
                    style: const TextStyle(color: ZenpexColors.offWhite),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text(_mesesCurto[m - 1])),
                    ],
                    onChanged: (v) => setState(() => _chamMes = v ?? _chamMes),
                    decoration: _dec('Mês'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _chamAno,
                    isExpanded: true,
                    dropdownColor: ZenpexColors.surface,
                    style: const TextStyle(color: ZenpexColors.offWhite),
                    items: [
                      for (var a = DateTime.now().year; a >= DateTime.now().year - 4; a--)
                        DropdownMenuItem(value: a, child: Text('$a')),
                    ],
                    onChanged: (v) => setState(() => _chamAno = v ?? _chamAno),
                    decoration: _dec('Ano'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _chamBuscando ? null : _buscarChamados,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZenpexColors.blue,
                  side: const BorderSide(color: ZenpexColors.blue),
                ),
                icon: _chamBuscando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: ZenpexColors.blue))
                    : const Icon(Icons.search, size: 18),
                label: Text(_chamBuscando ? 'Buscando…' : 'Buscar chamados'),
              ),
            ),
            if (_chamErro != null) ...[
              const SizedBox(height: 8),
              Text(_chamErro!,
                  style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 12)),
            ],
            ..._chamLista.map((c) {
              final cod = c.codigo;
              final marcado = cod != null && _chamSel.contains(cod);
              final jaVinc = cod != null && _chamJaVinc.contains(cod);
              return CheckboxListTile(
                value: marcado,
                onChanged: cod == null ? null : (_) => _toggleChamado(cod),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: ZenpexColors.blue,
                title: Text(
                  '#${c.codigo} · ${c.assunto.isEmpty ? "(sem assunto)" : c.assunto}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ZenpexColors.offWhite, fontSize: 13),
                ),
                subtitle: Text(
                  '${c.totalHoras}${jaVinc ? "  ·  já vinculado" : ""}',
                  style: const TextStyle(color: ZenpexColors.textMuted, fontSize: 12),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _secAnexos() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: ZenpexColors.outline),
          const SizedBox(height: 8),
          const Text('Documentos anexados',
              style: TextStyle(
                  color: ZenpexColors.offWhite, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_anexos.isEmpty)
            const Text('Nenhum documento anexado ainda.',
                style: TextStyle(color: ZenpexColors.textMuted)),
          ..._anexos.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ZenpexColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ZenpexColors.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 18, color: ZenpexColors.lightBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${a.nomeArquivo}  (${_tam(a.tamanho)})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: ZenpexColors.offWhite)),
                    ),
                    IconButton(
                      onPressed: () => _removerAnexo(a),
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Color(0xFFEB6B4D)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _enviandoAnexo ? null : _anexar,
            style: OutlinedButton.styleFrom(
              foregroundColor: ZenpexColors.blue,
              side: const BorderSide(color: ZenpexColors.blue),
            ),
            icon: _enviandoAnexo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: ZenpexColors.blue))
                : const Icon(Icons.attach_file),
            label: Text(_enviandoAnexo ? 'Enviando…' : 'Anexar documento'),
          ),
        ],
      ),
    );
  }

  String _tam(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
            initialDate: _data ?? DateTime.now(),
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
              Text(_data == null ? 'Selecionar' : brDate(_data),
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
