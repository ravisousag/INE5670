import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final void Function(String) goTo;

  const HomePage({super.key, required this.goTo});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const Text(
          "Sistema de Gerenciamento de Usuários NFC",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Gerencie usuários, cartões NFC e visualize logs de acesso.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Cards
        _menuCard(
          icon: Icons.person,
          color: Colors.blue,
          title: "Gerenciar Usuários",
          subtitle: "Cadastrar, editar e excluir usuários",
          onTap: () => goTo('users'),
        ),

        _menuCard(
          icon: Icons.list_alt,
          color: Colors.green,
          title: "Logs de Acesso",
          subtitle: "Histórico de acessos NFC",
          onTap: () => goTo('logs'),
        ),

        _menuCard(
          icon: Icons.credit_card,
          color: Colors.purple,
          title: "Cartões NFC",
          subtitle: "Associar cartões aos usuários",
          onTap: () {},
        ),
      ],
    );
  }

  Widget _menuCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
