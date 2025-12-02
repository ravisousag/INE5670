import 'package:flutter/material.dart';
import '../models/user.dart';
import '/api_service.dart';
import 'user_nfc_modal.dart';

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
  bool _hasNfc = false;

  bool get view => widget.mode == "view";

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user?.name ?? "");
    cpf = TextEditingController(text: widget.user?.cpf ?? "");
    email = TextEditingController(text: widget.user?.email ?? "");
    phone = TextEditingController(text: widget.user?.phone ?? "");
    uuid = TextEditingController(text: widget.user?.nfcCardUuid ?? "");
    _hasNfc = (widget.user?.nfcCardUuid ?? '').isNotEmpty;
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
          mainAxisSize: MainAxisSize.min,
          children: [
            _input("Nome", name, enabled: !view),
            _input("CPF", cpf, enabled: widget.mode == "create"),
            _input("Email", email, enabled: !view),
            _input("Telefone", phone, enabled: !view),
            const SizedBox(height: 8),
            // Seção NFC
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.nfc, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Cartão NFC',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Spacer(),
                      if (_hasNfc)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_hasNfc)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UUID: ${widget.user?.nfcCardUuid ?? ''}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: view ? null : _removeNfc,
                            icon: const Icon(Icons.delete),
                            label: const Text('Remover Cartão'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (widget.mode == "create")
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nenhum cartão associado',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Após criar o usuário, você poderá associar um cartão NFC.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    )
                  else if (widget.mode == "edit")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openNfcModal,
                        icon: const Icon(Icons.nfc_rounded),
                        label: const Text('Associar Cartão'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!view && widget.mode == "create")
          ElevatedButton(
            onPressed: _submitAndLinkNfc,
            child: const Text("Criar"),
          )
        else if (!view && widget.mode == "edit")
          ElevatedButton(
            onPressed: _submitEditUser,
            child: const Text("Salvar"),
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

  Future<void> _submitAndLinkNfc() async {
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
    };

    try {
      final resp = await ApiService.createUser(body);

      // Após criar, oferecer opção de vincular NFC
      _showNfcLinkDialog(resp['user']);
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      _err(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _submitEditUser() async {
    if (name.text.isEmpty ||
        email.text.isEmpty ||
        phone.text.isEmpty) {
      _err("Preencha todos os campos obrigatórios.");
      return;
    }

    final body = {
      "name": name.text,
      "email": email.text,
      "phone": phone.text,
    };

    try {
      await ApiService.updateUser(widget.user!.cpf, body);
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      _err(e.toString());
    }
  }

  void _showNfcLinkDialog(Map<String, dynamic> createdUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Associar Cartão NFC'),
        content: const Text('Deseja associar um cartão NFC a este usuário agora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Open NFC modal
              showDialog(
                context: ctx,
                builder: (c) => UserNfcModal(
                  cpf: createdUser['cpf'],
                  onSuccess: () {
                    widget.onSuccess();
                    setState(() {
                      _hasNfc = true;
                    });
                  },
                ),
              );
            },
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }

  void _openNfcModal() {
    // Use the navigator's context to ensure the dialog is shown on the current
    // route's BuildContext.
    showDialog(
      context: context,
      builder: (ctx) => UserNfcModal(
        cpf: widget.user!.cpf,
        onSuccess: () {
          widget.onSuccess();
          setState(() {
            _hasNfc = true;
          });
        },
      ),
    );
  }

  Future<void> _removeNfc() async {
    // Solicitar confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Cartão NFC'),
        content: const Text('Tem certeza que deseja remover o cartão NFC vinculado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.unlinkNfcFromUser(widget.user!.cpf);
      widget.onSuccess();
      setState(() {
        _hasNfc = false;
      });
      _err('Cartão NFC removido com sucesso');
    } catch (e) {
      _err(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _err(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
