import 'package:flutter/material.dart';
import 'dart:async';
import '../api_service.dart';
import '../models/user.dart';
import 'statistics_page.dart';

class HomePage extends StatefulWidget {
  final void Function(String) goTo;

  const HomePage({super.key, required this.goTo});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _statsTimer;
  int totalUsers = 0;
  int usersWithNfc = 0;
  int usersWithoutNfc = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Atualizar estatísticas a cada 3 segundos
    _statsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadStats();
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final users = await ApiService.getUsers();

      if (mounted) {
        setState(() {
          totalUsers = users.length;
          usersWithNfc = users
              .where((u) => u.nfcCardUuid != null && u.nfcCardUuid!.isNotEmpty)
              .length;
          usersWithoutNfc = totalUsers - usersWithNfc;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
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

          // Estatísticas em Card Roxo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Estatísticas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else ...[
                  _statRow("Total de usuários:", totalUsers.toString()),
                  const Divider(color: Colors.white24, height: 24),
                  _statRow("Com cartão NFC:", usersWithNfc.toString()),
                  const Divider(color: Colors.white24, height: 24),
                  _statRow("Sem cartão NFC:", usersWithoutNfc.toString()),
                ],
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Gráfico de Barras
          if (!loading)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Distribuição de Usuários",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildBarChart(),
                ],
              ),
            ),

          const SizedBox(height: 30),

          // Botão de Estatísticas em Destaque
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bar_chart,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ver Estatísticas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gráficos e análises detalhadas',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cards de Menu
          _menuCard(
            icon: Icons.person,
            color: Colors.blue,
            title: "Gerenciar Usuários",
            subtitle: "Cadastrar, editar e excluir usuários",
            onTap: () => widget.goTo('users'),
          ),

          _menuCard(
            icon: Icons.list_alt,
            color: Colors.green,
            title: "Logs de Acesso",
            subtitle: "Histórico de acessos NFC",
            onTap: () => widget.goTo('logs'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final maxValue = totalUsers > 0 ? totalUsers : 1;
    final withNfcPercent = totalUsers > 0 ? usersWithNfc / maxValue : 0.0;
    final withoutNfcPercent = totalUsers > 0 ? usersWithoutNfc / maxValue : 0.0;

    return Column(
      children: [
        _barChartRow(
          label: "Com NFC",
          value: usersWithNfc,
          percent: withNfcPercent,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        _barChartRow(
          label: "Sem NFC",
          value: usersWithoutNfc,
          percent: withoutNfcPercent,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _barChartRow({
    required String label,
    required int value,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "${(percent * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
