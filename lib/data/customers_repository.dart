import '../config/app_config.dart';
import '../services/api_client.dart';
import 'customer.dart';

class CustomersRepository {
  Future<List<Customer>> list() async {
    if (AppConfig.devPreview) return _sample;
    final data = await ApiClient.instance.get('/api/customers') as List<dynamic>;
    return data
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(Map<String, dynamic> payload) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.post('/api/customers', payload);
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.put('/api/customers/$id', payload);
  }

  Future<void> remove(int id) async {
    if (AppConfig.devPreview) return;
    await ApiClient.instance.delete('/api/customers/$id');
  }

  // Dados de exemplo só para prévia visual (AppConfig.devPreview).
  static final List<Customer> _sample = [
    Customer(
      id: 1,
      nome: 'Serra Diesel',
      origem: 'MILVUS',
      isAtivo: true,
      documento: '12.345.678/0001-90',
      emailContato: 'ti@serradiesel.com.br',
      telefone: '(54) 3000-0000',
      horasContratadasMensais: 40,
      milvusId: 1021,
    ),
    Customer(
      id: 2,
      nome: 'Casa Fagundes',
      origem: 'MILVUS',
      isAtivo: true,
      documento: '98.765.432/0001-10',
      emailContato: 'contato@casafagundes.com.br',
      telefone: '(54) 3111-1111',
      horasContratadasMensais: 20,
      milvusId: 1044,
    ),
    Customer(
      id: 3,
      nome: 'Kinix',
      origem: 'MANUAL',
      isAtivo: true,
      documento: '11.222.333/0001-44',
      emailContato: 'gabriel.ferreira@kinix.com.br',
      telefone: '(54) 3222-2222',
    ),
    Customer(
      id: 4,
      nome: 'Ultra Soluções',
      origem: 'MANUAL',
      isAtivo: false,
      documento: '44.555.666/0001-77',
      emailContato: 'diego.silva@ultra.com.br',
    ),
  ];
}
