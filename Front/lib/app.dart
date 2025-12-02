import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/users_page.dart';
import 'pages/logs_page.dart';

class NFCApp extends StatefulWidget {
  const NFCApp({super.key});

  @override
  State<NFCApp> createState() => _NFCAppState();
}

class _NFCAppState extends State<NFCApp> {
  int _currentIndex = 0;

  void goTo(String page) {
    switch (page) {
      case 'home':
        setState(() => _currentIndex = 0);
        break;
      case 'users':
        setState(() => _currentIndex = 1);
        break;
      case 'logs':
        setState(() => _currentIndex = 2);
        break;
      default:
        setState(() => _currentIndex = 0);
    }
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [HomePage(goTo: goTo), UsersPage(), LogsPage()];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sistema NFC",
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Sistema NFC",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: "Início"),
            NavigationDestination(icon: Icon(Icons.people), label: "Usuários"),
            NavigationDestination(icon: Icon(Icons.list), label: "Logs"),
          ],
        ),
      ),
    );
  }
}
