import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../api_service.dart';
import '../models/user.dart';
import '../models/log_entry.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool loading = true;
  List<User> users = [];
  List<LogEntry> logs = [];
  Timer? _refreshTimer;

  // Estatísticas
  int totalUsers = 0;
  int usersWithNfc = 0;
  int usersWithoutNfc = 0;
  int totalAccesses = 0;
  int authorizedAccesses = 0;
  int deniedAccesses = 0;
  Map<String, int> accessesByDay = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    // Atualizar a cada 5 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final fetchedUsers = await ApiService.getUsers();
      final fetchedLogs = await ApiService.getLogs();

      if (mounted) {
        setState(() {
          users = fetchedUsers;
          logs = fetchedLogs;
          _calculateStatistics();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _calculateStatistics() {
    // Estatísticas de usuários
    totalUsers = users.length;
    usersWithNfc = users
        .where((u) => u.nfcCardUuid != null && u.nfcCardUuid!.isNotEmpty)
        .length;
    usersWithoutNfc = totalUsers - usersWithNfc;

    // Estatísticas de acessos
    totalAccesses = logs.length;
    authorizedAccesses = logs.where((l) => l.userExists).length;
    deniedAccesses = logs.where((l) => !l.userExists).length;

    // Acessos por dia (últimos 7 dias)
    accessesByDay = {};
    final now = DateTime.now();

    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('dd/MM').format(date);
      accessesByDay[dateKey] = 0;
    }

    for (var log in logs) {
      final logDate = DateTime.parse(log.timestamp);
      final dateKey = DateFormat('dd/MM').format(logDate);

      if (accessesByDay.containsKey(dateKey)) {
        accessesByDay[dateKey] = accessesByDay[dateKey]! + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas do Sistema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Cards de resumo
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Total de Usuários',
                          totalUsers.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          'Total de Acessos',
                          totalAccesses.toString(),
                          Icons.touch_app,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Gráfico de Pizza - Usuários
                  _sectionTitle('Distribuição de Usuários'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: CustomPaint(
                            painter: PieChartPainter(
                              usersWithNfc: usersWithNfc,
                              usersWithoutNfc: usersWithoutNfc,
                            ),
                            child: const Center(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _legendItem(
                          'Com Cartão NFC',
                          usersWithNfc,
                          Colors.green,
                          totalUsers,
                        ),
                        const SizedBox(height: 8),
                        _legendItem(
                          'Sem Cartão NFC',
                          usersWithoutNfc,
                          Colors.orange,
                          totalUsers,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Gráfico de Pizza - Acessos
                  _sectionTitle('Status dos Acessos'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: CustomPaint(
                            painter: AccessPieChartPainter(
                              authorized: authorizedAccesses,
                              denied: deniedAccesses,
                            ),
                            child: const Center(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _legendItem(
                          'Autorizados',
                          authorizedAccesses,
                          Colors.green,
                          totalAccesses,
                        ),
                        const SizedBox(height: 8),
                        _legendItem(
                          'Negados',
                          deniedAccesses,
                          Colors.red,
                          totalAccesses,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Gráfico de Linha - Acessos por Dia
                  _sectionTitle('Acessos nos Últimos 7 Dias'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: CustomPaint(
                            painter: LineChartPainter(data: accessesByDay),
                            child: const Center(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Insights
                  _sectionTitle('Insights'),
                  const SizedBox(height: 16),
                  _insightCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _legendItem(String label, int value, Color color, int total) {
    final percentage = total > 0
        ? (value / total * 100).toStringAsFixed(1)
        : '0.0';
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          '$value ($percentage%)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _insightCard() {
    final nfcPercentage = totalUsers > 0
        ? (usersWithNfc / totalUsers * 100).toStringAsFixed(1)
        : '0.0';
    final successRate = totalAccesses > 0
        ? (authorizedAccesses / totalAccesses * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Análise do Sistema',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _insightItem(
            '$nfcPercentage% dos usuários já possuem cartão NFC vinculado',
          ),
          _insightItem('Taxa de sucesso nos acessos: $successRate%'),
          _insightItem('Total de $deniedAccesses tentativas de acesso negadas'),
          if (usersWithoutNfc > 0)
            _insightItem(
              'Ainda há $usersWithoutNfc usuário(s) sem cartão vinculado',
            ),
        ],
      ),
    );
  }

  Widget _insightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

// Painter para Gráfico de Pizza - Usuários
class PieChartPainter extends CustomPainter {
  final int usersWithNfc;
  final int usersWithoutNfc;

  PieChartPainter({required this.usersWithNfc, required this.usersWithoutNfc});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;

    final total = usersWithNfc + usersWithoutNfc;
    if (total == 0) return;

    final withNfcAngle = (usersWithNfc / total) * 2 * math.pi;

    // Com NFC (verde)
    final paintWithNfc = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      withNfcAngle,
      true,
      paintWithNfc,
    );

    // Sem NFC (laranja)
    final paintWithoutNfc = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + withNfcAngle,
      2 * math.pi - withNfcAngle,
      true,
      paintWithoutNfc,
    );

    // Círculo branco no centro
    final centerCircle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerCircle);

    // Texto no centro
    final centerTextPainter = TextPainter(
      text: TextSpan(
        text: total.toString(),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    centerTextPainter.layout();
    centerTextPainter.paint(
      canvas,
      Offset(
        center.dx - centerTextPainter.width / 2,
        center.dy - centerTextPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para Gráfico de Pizza - Acessos
class AccessPieChartPainter extends CustomPainter {
  final int authorized;
  final int denied;

  AccessPieChartPainter({required this.authorized, required this.denied});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;

    final total = authorized + denied;
    if (total == 0) return;

    final authorizedAngle = (authorized / total) * 2 * math.pi;

    // Autorizados (verde)
    final paintAuthorized = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      authorizedAngle,
      true,
      paintAuthorized,
    );

    // Negados (vermelho)
    final paintDenied = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + authorizedAngle,
      2 * math.pi - authorizedAngle,
      true,
      paintDenied,
    );

    // Círculo branco no centro
    final centerCircle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerCircle);

    // Texto no centro
    final centerTextPainter = TextPainter(
      text: TextSpan(
        text: total.toString(),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    centerTextPainter.layout();
    centerTextPainter.paint(
      canvas,
      Offset(
        center.dx - centerTextPainter.width / 2,
        center.dy - centerTextPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para Gráfico de Linha
class LineChartPainter extends CustomPainter {
  final Map<String, int> data;

  LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Encontrar valor máximo
    final maxValue = data.values.reduce(math.max);
    final yScale = maxValue > 0 ? chartHeight / maxValue : 1.0;

    final keys = data.keys.toList();
    final xStep = chartWidth / (keys.length - 1);

    // Desenhar eixos
    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2;

    // Eixo Y
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    // Eixo X
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // Desenhar linhas de grade
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (var i = 0; i <= 5; i++) {
      final y = padding + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Desenhar pontos e linha
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    bool firstPoint = true;

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final value = data[key]!;
      final x = padding + xStep * i;
      final y = size.height - padding - (value * yScale);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }

      // Desenhar ponto
      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      // Desenhar label no eixo X
      final labelPainter = TextPainter(
        text: TextSpan(
          text: key,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, size.height - padding + 10),
      );

      // Desenhar valor acima do ponto
      final valuePainter = TextPainter(
        text: TextSpan(
          text: value.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      valuePainter.layout();
      valuePainter.paint(canvas, Offset(x - valuePainter.width / 2, y - 20));
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
