import '../config/app_config.dart';
import '../services/api_client.dart';
import 'chamado.dart';

class MilvusRepository {
  Future<ChamadosReport> chamados(int clienteId, int ano, int mes) async {
    if (AppConfig.devPreview) {
      return ChamadosReport(
        clienteNome: 'Serra Diesel',
        ano: ano,
        mes: mes,
        chamados: [
          Chamado(
            codigo: 48213,
            assunto: 'Lentidão no servidor de arquivos',
            tecnico: 'Pedro',
            status: 'Finalizado',
            totalHoras: '2:30:00',
            horasDecimal: 2.5,
            horasMesDecimal: 2.5,
          ),
          Chamado(
            codigo: 48190,
            assunto: 'Configuração de backup',
            tecnico: 'Marco',
            status: 'Finalizado',
            totalHoras: '1:15:00',
            horasDecimal: 1.25,
            horasMesDecimal: 1.25,
          ),
        ],
        emAberto: [
          Chamado(
            codigo: 48301,
            assunto: 'Troca de switch da rede',
            tecnico: 'Pedro',
            status: 'Em atendimento',
            totalHoras: '0:45:00',
            horasDecimal: 0.75,
            horasMesDecimal: 0.75,
          ),
        ],
      );
    }
    final data = await ApiClient.instance.get(
      '/api/milvus/reports/chamados?cliente_id=$clienteId&ano=$ano&mes=$mes',
    ) as Map<String, dynamic>;
    return ChamadosReport.fromJson(data);
  }
}
