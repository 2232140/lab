
import 'package:flutter/material.dart';


const cal = Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('実験終了です。お疲れ様でした。'),
    Text('次のページで、アンケートにご協力お願いします。'),
    SizedBox(height: 30),
  ]
);

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('実験終了'),
      ),
      body: const Center(
        child: cal,
      ),
    );
  }
}