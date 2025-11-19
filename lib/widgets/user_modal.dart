import 'package:flutter/material.dart';
import '../models/user.dart';
import '/api_service.dart';

class UserModal extends StatefulWidget {
  final String mode; // create, edit, view
  final User? user;
  final VoidCallback onSuccess;

  const UserModal({
    super.key,
    required this.mode,
    this.user,
    required this.onSuccess,
  });

  @override
  State<UserModal> createState() => _UserModalState();
}

class _UserModalState extends State<UserModal> {
  late TextEditingController name;
  late TextEditingController cpf;
  late TextEditingController email;
  late TextEditingController phone;
  late TextEditingController uuid;

  bool get view => widget.mode == "view";

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user?.name ?? "");
    cpf = TextEditingController(text: widget.user?.cpf ?? "");
    email = TextEditingController(text: widget.user?.email ?? "");
    phone = TextEditingController(text: widget.user?.phone ?? "");
    uuid = TextEditingController(text: widget.user?.nfcCardUuid ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        {
          "create": "Novo Usuário",
          "edit": "Editar Usuário",
          "view": "Detalhes do Usuário",
        }[widget.mode]!,
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _input("Nome", name, enabled: !view),
            _input("CPF", cpf, enabled: widget.mode == "create"),
            _input("Email", email, enabled: !view),
            _input("Telefone", phone, enabled: !view),
            _input("UUID NFC (opcional)", uuid, enabled: !view),
          ],
        ),
      ),
      actions: [
        if (!view)
          ElevatedButton(
            onPressed: submit,
            child: Text(widget.mode == "create" ? "Criar" : "Salvar"),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(view ? "Fechar" : "Cancelar"),
        ),
      ],
    );
  }

  Widget _input(String label, TextEditingController c, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> submit() async {
    if (name.text.isEmpty ||
        cpf.text.isEmpty ||
        email.text.isEmpty ||
        phone.text.isEmpty) {
      _err("Preencha todos os campos obrigatórios.");
      return;
    }

    final body = {
      "name": name.text,
      "cpf": cpf.text,
      "email": email.text,
      "phone": phone.text,
      "nfc_card_uuid": uuid.text.isEmpty ? null : uuid.text.toLowerCase(),
    };

    try {
      if (widget.mode == "create") {
        await ApiService.createUser(body);
      } else {
        await ApiService.updateUser(widget.user!.cpf, body);
      }

      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      _err(e.toString());
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
