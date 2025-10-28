// 実験開始ボタンページ

import 'package:expt/no_audio.dart';
import 'package:flutter/material.dart';
import 'dart:math';


// 実験開始ページ
class Start extends StatelessWidget {
  const Start({super.key});

  @override
  Widget build(BuildContext context) {
    // ボタン
    final button = ElevatedButton(
      onPressed: () {
        // 条件リストを定義し、シャッフル
        List<String> conditions = ['breath', 'affirmation', 'music'];
        conditions.shuffle(Random()); // リストをランダムにシャッフル

        // ボタンが押されたらTimerScreenへ画面遷移し、シャッフルしたリストを渡す
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ArithmeticTaskScreen(
            title: '無条件テスト',
            // ここでシャッフルされたリストを渡す
            shuffledConditions: conditions,
            currentIndex: -1,
            userId: '001',
          )),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[50],
        foregroundColor: Colors.red,
        minimumSize: Size(150, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0)),
      ),
      child: const Text(
        '開始する',
        style: TextStyle(
          fontSize: 15,
        ),
      ),
    );

    // 縦に並べるカラム
    final col = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          '実験を開始する場合は、ボタンを押してください',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
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