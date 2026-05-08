import 'package:flutter/material.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Administración',
            style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
          child: Text('Control de usuarios y buses (Solo Dueños)')),
    );
  }
}
