import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('実験終了'),
      ),
      body: const Center(
        child: Text(
          '実験終了です！',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}