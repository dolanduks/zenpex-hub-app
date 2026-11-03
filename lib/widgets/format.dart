/// Formatação PT-BR simples, sem depender de pacote de intl.
String brDate(DateTime? d) {
  if (d == null) return '—';
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year}';
}

String brMoney(num? v) {
  if (v == null) return 'R\$ 0,00';
  final neg = v < 0;
  final cents = (v.abs() * 100).round();
  final reais = (cents ~/ 100).toString();
  final dec = (cents % 100).toString().padLeft(2, '0');
  final buf = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) buf.write('.');
    buf.write(reais[i]);
  }
  return '${neg ? '-' : ''}R\$ $buf,$dec';
}

DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
