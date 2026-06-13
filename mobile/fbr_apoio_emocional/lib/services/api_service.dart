import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Usar 10.255.136.217 para dispositivos físicos
  // Usar 10.0.2.2 para emulador Android
  // Usar http://localhost:8080 para web
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService({this.baseUrl = 'http://10.255.136.217:8080'});

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  Map<String, String> _headers(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final res = await http.post(url,
        headers: _headers(null), body: jsonEncode({'email': email, 'password': password}));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      final token = body['token'] as String?;
      if (token != null) await saveToken(token);
      return body;
    }

    throw Exception(body['message'] ?? 'Login failed');
  }

  Future<Map<String, dynamic>> signup(String email, String password, String nickname) async {
    final url = Uri.parse('$baseUrl/api/auth/signup');
    final res = await http.post(url,
        headers: _headers(null), body: jsonEncode({'email': email, 'password': password, 'nickname': nickname}));

    final body = jsonDecode(res.body);
    if (res.statusCode == 201) {
      final token = body['token'] as String?;
      if (token != null) await saveToken(token);
      return body;
    }

    throw Exception(body['message'] ?? 'Signup failed');
  }

  Future<List<dynamic>> listarAtendimentos() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/atendimento');
    final res = await http.get(url, headers: _headers(token));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }

    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? 'Failed to fetch atendimentos');
  }

  Future<Map<String, dynamic>> criarAtendimento(String descricaoInicial) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/atendimento');
    final res = await http.post(url,
        headers: _headers(token), body: jsonEncode({'descricaoInicial': descricaoInicial}));

    final body = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return body as Map<String, dynamic>;
    }

    throw Exception(body['message'] ?? 'Failed to create atendimento');
  }

  Future<Map<String, dynamic>> atualizarAtendimento(String id, {String? descricaoInicial, String? status}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/atendimento/$id');
    final payload = <String, dynamic>{};
    if (descricaoInicial != null) payload['descricaoInicial'] = descricaoInicial;
    if (status != null) payload['status'] = status;

    final res = await http.patch(url, headers: _headers(token), body: jsonEncode(payload));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return body as Map<String, dynamic>;
    }

    throw Exception(body['message'] ?? 'Failed to update atendimento');
  }

  Future<void> excluirAtendimento(String id) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/atendimento/$id');
    final res = await http.delete(url, headers: _headers(token));

    if (res.statusCode == 204) {
      return;
    }

    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? 'Failed to delete atendimento');
  }
}
