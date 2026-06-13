import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Usar 10.255.136.217 para dispositivos físicos
  // Usar 10.0.2.2 para emulador Android
  // Usar http://localhost:8080 para web
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedToken;

  ApiService({this.baseUrl = 'http://10.255.136.217:8080'});

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
    _cachedToken = token;
    // ignore: avoid_print
    print('[ApiService] saveToken token=$_cachedToken');
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: 'token');
    // ignore: avoid_print
    print('[ApiService] getToken loaded=$_cachedToken');
    return _cachedToken;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
    _cachedToken = null;
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
    final res = await http.post(url, headers: _headers(null), body: jsonEncode({'email': email, 'password': password}));

    // ignore: avoid_print
    print('[ApiService] login status=${res.statusCode} body=${res.body}');
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      final token = body['token'] as String?;
      if (token != null) {
        _cachedToken = token;
        await saveToken(token);
      } else {
        // tentar extrair token do Set-Cookie quando o backend só seta cookie
        final setCookie = res.headers['set-cookie'];
        // ignore: avoid_print
        print('[ApiService] login set-cookie=$setCookie');
        if (setCookie != null) {
          final m = RegExp(r'token=([^;]+)').firstMatch(setCookie);
          if (m != null) {
            final cookieToken = m.group(1);
            if (cookieToken != null) {
              _cachedToken = cookieToken;
              await saveToken(cookieToken);
            }
          }
        }
      }
      return body;
    }

    throw Exception(body['message'] ?? 'Login failed');
  }

  Future<Map<String, dynamic>> signup(String email, String password, String nickname) async {
    final url = Uri.parse('$baseUrl/api/auth/signup');
    final res = await http.post(url, headers: _headers(null), body: jsonEncode({'email': email, 'password': password, 'nickname': nickname}));

    // ignore: avoid_print
    print('[ApiService] signup status=${res.statusCode} body=${res.body}');
    final body = jsonDecode(res.body);
    if (res.statusCode == 201) {
      final token = body['token'] as String?;
      if (token != null) {
        _cachedToken = token;
        await saveToken(token);
      } else {
        final setCookie = res.headers['set-cookie'];
        // ignore: avoid_print
        print('[ApiService] signup set-cookie=$setCookie');
        if (setCookie != null) {
          final m = RegExp(r'token=([^;]+)').firstMatch(setCookie);
          if (m != null) {
            final cookieToken = m.group(1);
            if (cookieToken != null) {
              _cachedToken = cookieToken;
              await saveToken(cookieToken);
            }
          }
        }
      }
      return body;
    }

    throw Exception(body['message'] ?? 'Signup failed');
  }

  Future<List<dynamic>> listarAtendimentos() async {
    final token = await getToken();
    // debug
    // ignore: avoid_print
    print('[ApiService] listarAtendimentos token=$token');
    final url = Uri.parse('$baseUrl/api/atendimento');
    final headers = _headers(token);
    // ignore: avoid_print
    print('[ApiService] listarAtendimentos headers=$headers');
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }

    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? 'Failed to fetch atendimentos');
  }

  Future<Map<String, dynamic>> criarAtendimento(String descricaoInicial) async {
    final token = await getToken();
    // ignore: avoid_print
    print('[ApiService] criarAtendimento token=$token');
    final url = Uri.parse('$baseUrl/api/atendimento');
    final headers = _headers(token);
    // ignore: avoid_print
    print('[ApiService] criarAtendimento headers=$headers');
    final res = await http.post(url, headers: headers, body: jsonEncode({'descricaoInicial': descricaoInicial}));

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

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    // aceitar 200 ou 202 (queued)
    if (res.statusCode == 200 || res.statusCode == 202) {
      return body as Map<String, dynamic>;
    }

    throw Exception((body is Map && body['message']) != null ? body['message'] : 'Failed to update atendimento');
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

  Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/auth/me');
    final res = await http.get(url, headers: _headers(token));
    // ignore: avoid_print
    print('[ApiService] getMe status=${res.statusCode} body=${res.body} headers=${res.headers}');
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return body as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Failed to get user');
  }
}
