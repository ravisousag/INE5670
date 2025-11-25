import 'package:flutter/material.dart';
import '../models/user.dart';
import '/api_service.dart';
import '../widgets/user_modal.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> users = [];
  List<User> filtered = [];
  bool loading = false;
  String search = "";

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);

    try {
      users = await ApiService.getUsers();
      filter();
    } catch (e) {
      _error(e.toString());
    }

    setState(() => loading = false);
  }

  void filter() {
    setState(() {
      filtered = users
          .where(
            (u) =>
                u.name.toLowerCase().contains(search.toLowerCase()) ||
                u.cpf.contains(search) ||
                u.email.toLowerCase().contains(search.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Gerenciar Usuários",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _openModal(mode: "create"),
              icon: const Icon(Icons.add),
              label: const Text("Novo Usuário"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: "Buscar por nome, CPF ou email...",
          ),
          onChanged: (v) {
            search = v;
            filter();
          },
        ),
        const SizedBox(height: 20),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? const Center(child: Text("Nenhum usuário encontrado"))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final u = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Text(u.name),
                        subtitle: Text("${u.email} • CPF: ${u.cpf}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () =>
                                  _openModal(mode: "view", user: u),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _openModal(mode: "edit", user: u),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _delete(u.cpf),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _delete(String cpf) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Usuário"),
        content: const Text("Tem certeza que deseja excluir?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteUser(cpf);
      fetchUsers();
    } catch (e) {
      _error(e.toString());
    }
  }

  void _openModal({required String mode, User? user}) {
    showDialog(
      context: context,
      builder: (ctx) =>
          UserModal(mode: mode, user: user, onSuccess: fetchUsers),
    );
  }

  void _error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Erro: $msg")));
  }
}
