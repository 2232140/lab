// 実験開始ボタンページ

import 'package:expt/no_audio.dart';
import 'package:flutter/material.dart';


// 実験開始ページ
class Start extends StatelessWidget {
  const Start({super.key});

  @override
  Widget build(BuildContext context) {
    // ボタン
    final button = ElevatedButton(
      onPressed: () {
        // ボタンが押されたらTimerScreenへ画面遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TimerScreen(title: '無条件テスト')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
      ),
      child: const Text('開始する'),
    );

    // 縦に並べるカラム
    final col = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('実験を開始する場合は、ボタンを押してください'),
        button,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('実験開始ページ'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: col,
      ),
    );
  }
}