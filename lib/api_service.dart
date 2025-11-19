import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/log_entry.dart';

class ApiService {
  static const base = 'http://192.168.0.146:5000/api';

  // -------------------------
  // USERS
  // -------------------------
  static Future<List<User>> getUsers() async {
    final url = Uri.parse('$base/users');
    final res = await http.get(url);

    final data = jsonDecode(res.body);
    final List users = data['users'] ?? [];

    return users.map((e) => User.fromJson(e)).toList();
  }

  static Future<String> createUser(Map<String, dynamic> body) async {
    final url = Uri.parse('$base/users');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Erro desconhecido ao criar usuário');
    }

    // Garantir retorno SEMPRE
    return data['message'] ?? 'Usuário criado com sucesso';
  }

  static Future<String> updateUser(
    String cpf,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$base/users/cpf/$cpf');

    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Erro desconhecido ao criar usuário');
    }

    // Garantir retorno SEMPRE
    return data['message'] ?? 'Usuário criado com sucesso';
  }

  static Future<String> deleteUser(String cpf) async {
    final url = Uri.parse('$base/users/cpf/$cpf');
    final res = await http.delete(url);

    final data = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Erro desconhecido ao criar usuário');
    }

    // Garantir retorno SEMPRE
    return data['message'] ?? 'Usuário criado com sucesso';
  }

  // -------------------------
  // LOGS
  // -------------------------
  static Future<List<LogEntry>> getLogs() async {
    final url = Uri.parse('$base/logs');
    final res = await http.get(url);

    final data = jsonDecode(res.body);
    final List logs = data['logs'] ?? [];

    return logs.map((e) => LogEntry.fromJson(e)).toList();
  }

  // LISTAR CARTÕES NFC
  static Future<Map<String, dynamic>> listCards() async {
    final url = Uri.parse('$base/nfc/all');
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Erro ao buscar cartões NFC");
    }

    final data = jsonDecode(res.body);
    return data;
  }
}
