// 音声テスト用ページ

import 'package:flutter/material.dart';


class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {

    // ボタン操作確認クラス（テスト用）
    void action() {
      debugPrint('ボタンが押されました');
    }
    // ボタン
    final button = ElevatedButton(
      // ボタンを押したら、音声を再生する
      onPressed: action,
      child:Text('音声を再生する'),
    );

    // 縦に並べるカラム
    final col = Column(
     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('下のボタンを押し、音量の調節を行ってください。'),
        button,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声確認用ページ'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: col,
      ),
    );
  }
}