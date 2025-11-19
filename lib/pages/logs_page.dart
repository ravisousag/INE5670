import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      logs = await ApiService.getLogs();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }

    setState(() => loading = false);
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
              "Logs de Acesso NFC",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("Total: ${logs.length}"),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : logs.isEmpty
              ? const Center(child: Text("Nenhum log registrado"))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final l = logs[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          "UUID: ${l.nfcUuid}",
                          style: const TextStyle(fontFamily: "monospace"),
                        ),
                        subtitle: Text(
                          DateFormat(
                            "dd/MM/yyyy HH:mm",
                          ).format(DateTime.parse(l.timestamp)),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: l.userExists
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l.userExists ? "Sucesso" : "Não encontrado",
                            style: TextStyle(
                              color: l.userExists
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
