import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

/// Cliente HTTP da API do hub, com token Microsoft no header.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Object body) => _send('POST', path, body);
  Future<dynamic> put(String path, Object body) => _send('PUT', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final token = await AuthService.instance.validAccessToken();
    if (token == null) {
      throw ApiException(401, 'Sessão expirada. Entre novamente.');
    }
    final uri = Uri.parse('${AppConfig.apiBase}$path');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final client = http.Client();
    http.Response r;
    try {
      switch (method) {
        case 'POST':
          r = await client.post(uri, headers: headers, body: jsonEncode(body));
        case 'PUT':
          r = await client.put(uri, headers: headers, body: jsonEncode(body));
        case 'DELETE':
          r = await client.delete(uri, headers: headers);
        default:
          r = await client.get(uri, headers: headers);
      }
    } finally {
      client.close();
    }
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(r.bodyBytes));
    }
    throw ApiException(r.statusCode, _errorMessage(r));
  }

  /// Upload multipart (ex.: importação OFX/Excel).
  Future<dynamic> uploadFile(
    String path, {
    required Map<String, String> fields,
    required String filePath,
    String fileField = 'arquivo',
  }) async {
    final token = await AuthService.instance.validAccessToken();
    if (token == null) {
      throw ApiException(401, 'Sessão expirada. Entre novamente.');
    }
    final uri = Uri.parse('${AppConfig.apiBase}$path');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath));
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(r.bodyBytes));
    }
    throw ApiException(r.statusCode, _errorMessage(r));
  }

  String _errorMessage(http.Response r) {
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map && j['detail'] != null) return j['detail'].toString();
    } catch (_) {}
    return 'Erro ${r.statusCode}';
  }
}
