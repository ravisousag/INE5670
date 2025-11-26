import 'dart:convert';
import 'package:http/http.dart' as http;

class NfcService {
  static const base = 'http://127.0.0.1:5000';

  /// Vincula um cartão NFC já registrado a um usuário
  /// 
  /// Fluxo:
  /// 1. Usuário criado no app
  /// 2. Usuário scanneia o cartão NFC
  /// 3. UUID é enviado para vincular ao usuário
  static Future<Map<String, dynamic>> linkNfcToUser(
    String nfcCardUuid,
    String cpf,
  ) async {
    final url = Uri.parse('$base/api/nfc/link');

    final body = {
      'nfc_card_uuid': nfcCardUuid,
      'cpf': cpf,
    };

    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Erro ao vincular cartão NFC');
    }

    return data;
  }



  /// Remove a associação de um cartão NFC de um usuário
  static Future<Map<String, dynamic>> unlinkNfcFromUser(String cpf) async {
    final url = Uri.parse('$base/api/nfc/unlink');

    final body = {'cpf': cpf};

    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Erro ao desvinculcar cartão NFC');
    }

    return data;
  }



  /// Inicia uma sessão de pareamento para um usuário (chamada pelo app)
  /// Body: { 'cpf': '12345678900' }
  /// Retorna: { pair_token, expires_at, vinculado, user_id }
  static Future<Map<String, dynamic>> startPairing(String cpf) async {
    final url = Uri.parse('$base/api/nfc/pair_start');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cpf': cpf}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 201) {
      throw Exception(data['error'] ?? 'Erro ao iniciar pareamento');
    }

    return data;
  }

  /// Consulta o status de um token de pareamento
  /// Retorna o status ou lança exceção se houver erro
  static Future<Map<String, dynamic>> getPairStatus(String pairToken) async {
    final url = Uri.parse('$base/api/nfc/pair_status/$pairToken');
    final res = await http.get(url);

    final data = jsonDecode(res.body);
    
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Erro ao consultar status de pareamento');
    }

    return data;
  }
}
