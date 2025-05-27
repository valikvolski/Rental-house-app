import 'package:flutter/material.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админ-панель')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home_repair_service),
            title: const Text('Модерация объявлений'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.report_problem),
            title: const Text('Жалобы и поддержка'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Статистика'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
} 