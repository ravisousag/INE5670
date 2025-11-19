import 'package:flutter/material.dart';
import '../api_service.dart';

class ListCardsPage extends StatefulWidget {
  const ListCardsPage({super.key});

  @override
  State<ListCardsPage> createState() => _ListCardsPageState();
}

class _ListCardsPageState extends State<ListCardsPage> {
  List cards = [];

  void load() async {
    final res = await ApiService.listCards();
    setState(() => cards = res["cards"]);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cartões Cadastrados")),
      body: ListView.builder(
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final card = cards[i];
          return ListTile(title: Text(card["nfc_uuid"]));
        },
      ),
    );
  }
}
