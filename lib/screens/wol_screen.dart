import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../theme.dart';

class WolScreen extends StatefulWidget {
  const WolScreen({super.key});

  @override
  State<WolScreen> createState() => _WolScreenState();
}

enum _St { idle, sending, ok, error }

class _WolScreenState extends State<WolScreen> {
  _St _st = _St.idle;
  String _msg = '';

  Future<void> _wake() async {
    setState(() => _st = _St.sending);
    try {
      if (AppConfig.devPreview) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _st = _St.ok;
          _msg = 'Pacote mágico enviado para a máquina.';
        });
        return;
      }
      final r = await ApiClient.instance.post('/api/wol', {});
      setState(() {
        _st = _St.ok;
        _msg = (r is Map && r['detail'] != null)
            ? r['detail'].toString()
            : 'Pacote enviado.';
      });
    } catch (e) {
      setState(() {
        _st = _St.error;
        _msg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZenpexColors.surface,
        title: const Text('Wake-on-LAN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2994A).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.power_settings_new,
                    size: 54, color: Color(0xFFF2994A)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ligar máquina remota',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ZenpexColors.offWhite),
              ),
              const SizedBox(height: 8),
              const Text(
                'Envia o pacote mágico (Wake-on-LAN) para a máquina '
                'configurada na rede da Zenpex.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ZenpexColors.textMuted),
              ),
              const SizedBox(height: 28),
              if (_st == _St.ok || _st == _St.error)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (_st == _St.ok
                            ? ZenpexColors.ok
                            : const Color(0xFFEB6B4D))
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _st == _St.ok ? Icons.check_circle : Icons.error_outline,
                        color: _st == _St.ok
                            ? ZenpexColors.ok
                            : const Color(0xFFEB6B4D),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_msg,
                            style: const TextStyle(
                                color: ZenpexColors.offWhite)),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF2994A),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _st == _St.sending ? null : _wake,
                  icon: _st == _St.sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black),
                        )
                      : const Icon(Icons.bolt),
                  label: Text(_st == _St.sending ? 'Enviando…' : 'Ligar agora'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
