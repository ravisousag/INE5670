import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/log_entry.dart';
import 'services/nfc_service.dart';

class ApiService {
  static const base = 'http://127.0.0.1:5000';

  // -------------------------
  // USERS
  // -------------------------
  static Future<List<User>> getUsers() async {
    final url = Uri.parse('$base/api/users');
    final res = await http.get(url);

    final data = jsonDecode(res.body);
    final List users = data['users'] ?? [];

    return users.map((e) => User.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    final url = Uri.parse('$base/api/users');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Erro desconhecido ao criar usuário');
    }

    // Retornar o objeto de resposta completo (inclui 'user' e 'message')
    return data as Map<String, dynamic>;
  }

  static Future<String> updateUser(
    String cpf,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$base/api/users/cpf/$cpf');

    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Erro desconhecido ao criar usuário');
    }

    return data['message'] ?? 'Usuário criado com sucesso';
  }

  static Future<String> deleteUser(String cpf) async {
    final url = Uri.parse('$base/api/users/cpf/$cpf');
    final res = await http.delete(url);

    final data = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Erro desconhecido ao criar usuário');
    }

    return data['message'] ?? 'Usuário criado com sucesso';
  }

  // -------------------------
  // LOGS
  // -------------------------
  static Future<List<LogEntry>> getLogs() async {
    final url = Uri.parse('$base/api/logs');
    final res = await http.get(url);

    final data = jsonDecode(res.body);
    final List logs = data['logs'] ?? [];

    return logs.map((e) => LogEntry.fromJson(e)).toList();
  }

  // -------------------------
  // NFC INTEGRATION
  // -------------------------

  /// Vincula um cartão NFC a um usuário
  static Future<String> linkNfcToUser(String nfcCardUuid, String cpf) async {
    try {
      final result = await NfcService.linkNfcToUser(nfcCardUuid, cpf);
      return result['message'] ?? 'Cartão vinculado com sucesso';
    } catch (e) {
      throw Exception(e.toString());
    }
  }



  /// Remove associação de cartão NFC
  static Future<String> unlinkNfcFromUser(String cpf) async {
    try {
      final result = await NfcService.unlinkNfcFromUser(cpf);
      return result['message'] ?? 'Cartão desvinculado com sucesso';
    } catch (e) {
      throw Exception(e.toString());
    }
  }


}
