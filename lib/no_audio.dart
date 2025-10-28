// 無条件テストページ

// no_audio.dart (修正版 - タイマー付き四則演算タスクと進行管理)

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:expt/rest.dart'; // RestScreen の定義をインポート
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

// 四則演算タスク画面
class ArithmeticTaskScreen extends StatefulWidget {
    final String userId;
    final String title;
    // ⚡️ 復活: シャッフルされた条件リスト
    final List<String> shuffledConditions; 
    // ⚡️ 復活: 現在のインデックス
    final int currentIndex; 

    const ArithmeticTaskScreen({
      super.key,
      required this.userId,
      required this.title,
      // ⚡️ 追加: シャッフルプロパティ
      required this.shuffledConditions, 
      required this.currentIndex,
    });

  @override
  State<ArithmeticTaskScreen> createState() => _ArithmeticTaskScreenState();
}

class _ArithmeticTaskScreenState extends State<ArithmeticTaskScreen> {
  final int _totalTime = 60; // 制限時間（秒）
  int _counter = 60;
  late Timer _timer;
  // ⚡️ 修正: _answerContoroller -> _answerController にタイポ修正
  final TextEditingController _answerController = TextEditingController(); 
  final Random _random = Random();
  final player = AudioPlayer(); 

  // タスクログ用メトリクス
  int _correctCount = 0;
  int _totalAnswered = 0;

  // 現在のタスク
  String _currentQuestion = '';
  int _currentAnswer = 0;

  DateTime? startTime;
  DateTime? endTime;

  @override
  void initState() {
    super.initState();
    _generateNewQuestion(); // 最初の問題生成
    startTime = DateTime.now();
    _counter = _totalTime;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        setState(() {
          _counter--;
          if (_counter <= 0) {
            timer.cancel();
            endTime = DateTime.now();
            _sendTaskLogToServer();
            _playAudioAndNavigator(); // タイマー終了時に通知音再生と画面遷移
          }
        });
      }
    );
  }

  // 問題生成ロジック (変更なし)
  void _generateNewQuestion() {
    final a = _random.nextInt(89) + 10;
    final b = _random.nextInt(8) + 2;

    _currentQuestion = '$a + $b = ?';
    _currentAnswer = a + b;
  }

  // 回答チェックとメトリクス更新 (変更なし)
  void _checkAnswer() {
    if (_answerController.text.isEmpty) return;

    final userAnswer = int.tryParse(_answerController.text);

    if (userAnswer == null) {
      _answerController.clear();
      return;
    }

    setState(() {
      _totalAnswered++;
      if (userAnswer == _currentAnswer) {
        _correctCount++;
      }
      _answerController.clear();
      _generateNewQuestion();
    });
  }

  // ログ送信関数 (正答率を含むデータを送信)
  Future<void> _sendTaskLogToServer() async {
    const url = 'http://localhost:3000/api/experiment-log'; // サーバーのURL

    final accuracyRate = _totalAnswered > 0 ? (_correctCount / _totalAnswered) : 0.0;
    
    final data = {
      'user_id': widget.userId,
      'start_time': startTime!.toIso8601String(),
      'end_time': endTime!.toIso8601String(),
      'test_type': widget.title,
      // ⚡️ conditionに現在の実験条件を設定
      'condition': widget.shuffledConditions[widget.currentIndex], 
      
      // 計算結果を送信
      'total_answered': _totalAnswered,
      'correct_count': _correctCount,
      'accuracy_rate': accuracyRate,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: { 'Content-Type': 'application/json', },
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('タスクログをサーバーに正常送信');
      } else {
        debugPrint('データ送信失敗。Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ネットワークエラー: $e');
    }
  }

  // 画面遷移ロジック (シャッフル機能の保持)
  void _playAudioAndNavigator() async {
    // ローカルセットアップの音声を再生
    await player.setSource(AssetSource('audio/alarm.mp3'));
    await player.resume(); 

    player.onPlayerComplete.listen((_) {
      if (mounted) {
        final nextIndex = widget.currentIndex + 1;
        
        // ⚡️ 次の実験条件をチェック
        if (nextIndex < widget.shuffledConditions.length) {
          // 次のタスクがある場合、RestScreenに遷移
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RestScreen(
                title: '休憩時間',
                shuffledConditions: widget.shuffledConditions,
                currentIndex: nextIndex, // ⚡️ インデックスをインクリメントして渡す
                userId: widget.userId, // userId も渡す必要がある (RestScreenのコードによる)
              ),
            ),
          );
        } else {
          // すべてのタスクが終了した場合、ResultScreen (アンケートなど) に遷移
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // 遷移先の画面はプロジェクトに合わせて修正
              builder: (context) => const Placeholder(), 
            ),
          );
        }
      }
    });
  }
  
  @override
  void dispose() {
    _timer.cancel();
    player.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 秒数を見やすい形式に変換
    String formattedTime = "${(_counter % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // タイマー表示
              Text(
                '残り時間: $formattedTime 秒' ,
                style: const TextStyle(fontSize: 24, color: Colors.red),
              ),

              const SizedBox(height: 40),

              // 問題表示
              Text(
                _currentQuestion,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // 解答入力欄
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _answerController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28),
                  decoration: const InputDecoration(
                    hintText: '答えを入力',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _checkAnswer(), // Enterキーでチェック
                ),
              ),
              const SizedBox(height: 30),

              // 回答ボタン
              ElevatedButton(
                onPressed: _checkAnswer, 
                child: const Text('回答'),
              ),

              const SizedBox(height: 40),
              
              // 現在のスコア表示
              Text(
                '正答数: $_correctCount / 回答数: $_totalAnswered',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          )
        )
      ),
    );
  }
}