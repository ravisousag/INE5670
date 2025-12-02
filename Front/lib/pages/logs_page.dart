import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../models/log_entry.dart';
import '../api_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<LogEntry> logs = [];
  bool loading = false;
  Timer? _autoRefreshTimer;
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    load();
    // Atualizar automaticamente a cada 2 segundos
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    if (_autoRefresh) {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted && _autoRefresh) {
          load(silent: true);
        }
      });
    }
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      setState(() => loading = true);
    }

    try {
      final newLogs = await ApiService.getLogs();
      
      if (mounted) {
        setState(() {
          logs = newLogs;
          if (!silent) loading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e")),
        );
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Header com título e controles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Logs de Acesso NFC",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Total: ${logs.length}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _autoRefresh ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _autoRefresh ? "Atualização automática" : "Pausado",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botão de atualização manual
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => load(),
                tooltip: "Atualizar agora",
              ),
              
              // Toggle atualização automática
              IconButton(
                icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _autoRefresh = !_autoRefresh;
                    _startAutoRefresh();
                  });
                },
                tooltip: _autoRefresh ? "Pausar atualização" : "Retomar atualização",
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Estatísticas rápidas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _quickStatCard(
                  "Acessos",
                  logs.length.toString(),
                  Icons.list,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickStatCard(
                  "Autorizados",
                  logs.where((l) => l.userExists).length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickStatCard(
                  "Negados",
                  logs.where((l) => !l.userExists).length.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Lista de logs
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Nenhum log registrado",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Os logs aparecerão aqui quando\nalguém passar um cartão NFC",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: logs.length,
                        itemBuilder: (ctx, i) {
                          final l = logs[i];
                          return _logCard(l);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _quickStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logCard(LogEntry l) {
    final isSuccess = l.userExists;
    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.cancel;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "UUID: ${l.nfcUuid}",
                    style: const TextStyle(
                      fontFamily: "monospace",
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat("dd/MM/yyyy HH:mm:ss").format(
                      DateTime.parse(l.timestamp),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isSuccess ? "Autorizado" : "Negado",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}