// ホーム

import 'package:expt/start.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class Home extends StatelessWidget {
  const Home({super.key});

  // 進むボタンを押した時
  push(BuildContext context) {
    // 音量確認ページに進む
    context.push('/b');
  }
  
  @override
  Widget build(BuildContext context) {
    // 画面の上に表示するバー
    final appBar = AppBar(
      backgroundColor: Colors.blue,
      title: const Text('ホーム画面'),
    );

    // 進むボタン
    final pushButton = ElevatedButton(
      onPressed: () => push(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple[50],
      ),
      child: const Text(
        '音声テスト',
        style: TextStyle(
          fontSize: 15,
        ),
      ),
    );

    final button2 = ElevatedButton(
      onPressed: () {
        // ボタンが押されたらStart()へ画面遷移
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Start()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple[50],
      ),
      child: const Text(
        '実験開始',
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
          '実験前に行ってください。',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        pushButton,
        Text(
          '実験を始める場合は、\n下のボタンを押してください。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        button2,
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: Center(
        child: col,
      ),
    );
  }
}