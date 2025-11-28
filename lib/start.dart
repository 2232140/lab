// 実験開始ボタンページ

import 'package:expt/no_audio.dart'; // ArithmeticTaskScreenをインポート
import 'package:flutter/material.dart';
import 'dart:math';


class Start extends StatefulWidget {
  const Start({super.key});

  @override
  State<Start> createState() => _StartScreenState();
}

class _StartScreenState extends State<Start> {
  // ユーザーID入力用のコントローラー
  final TextEditingController _controller = TextEditingController(); 
  // 三つの実験条件
  final List<String> _baseConditions = ['呼吸法', 'アファメーション', '音楽リラクゼーション'];

  // 実験条件のシャッフル処理
  List<String> _shuffleConditions() {
    // リストを複製してシャッフル
    final List<String> shuffledList = List.from(_baseConditions);
    shuffledList.shuffle(Random());

    // '無条件'を先頭に追加して、完全な実験条件リストを作成
    final List<String> finalConditions = ['無条件'];
    finalConditions.addAll(shuffledList);
    return finalConditions;
  }

  // 実験開始ボタンが押された時の処理
  void _startExperiment() {
    final userId = _controller.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('被験者IDを入力してください。')),
      );
      return;
    }

    // シャッフルされた条件リストを生成
    final shuffledConditions = _shuffleConditions();

    // 無条件テストへ遷移
    // currentIndex：０は最初の無条件を指す
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ArithmeticTaskScreen(
          userId: userId, // ユーザーIDを渡す
          title: '無条件テスト',
          shuffledConditions: shuffledConditions,
          currentIndex: 0, 
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('実験開始'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '被験者IDを入力してください',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: '例: A001',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _startExperiment(),
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _startExperiment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    '実験開始',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}