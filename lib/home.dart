// ホーム

import 'package:expt/practice.dart';
import 'package:expt/start.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

// アプリ
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

// UIウィジェット
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // ボタン
    final buttton1 = ElevatedButton(
      onPressed: () {
        // ボタンが押されたらPracticePage()へ画面遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PracticePage()),
        );
      }, 
      child: const Text('音声テスト'),
    );

    final button2 = ElevatedButton(
      onPressed: () {
        // ボタンが押されたらStart()へ画面遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Start()),
        );
      },
      child: const Text('実験開始'),
    );

    // 縦に並べるカラム
    final col = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buttton1,
        button2,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: col,
      ),
    );
  }
}