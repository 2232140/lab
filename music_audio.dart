// 音楽リラクゼーションテストページ

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:expt/rest.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'finish.dart';
import 'dart:math';

// 1問ごとの詳細ログのデータ構造
class TaskLogEntry {
  final String question;
  final int correctAnswer;
  final int? userAnswer;
  final bool isCorrect;
  final int timeStampSec;
  final String difficultyLevel;

  TaskLogEntry({
    required this.question,
    required this.correctAnswer,
    this.userAnswer,
    required this.isCorrect,
    required this.timeStampSec,
    required this.difficultyLevel,
  });

  // サーバー送信用のJSON形式に変換
  Map<String, dynamic> toJson() => {
    'question': question,
    'correct_answer': correctAnswer,
    'user_answer': userAnswer,
    'is_correct': isCorrect,
    'time_stamp_sec': timeStampSec,
    'difficulty_level': difficultyLevel,
  };
}

// タイマー画面
class MusicScreen extends StatefulWidget {
  const MusicScreen({
    super.key, 
    required this.userId,
    required this.title,
    required this.shuffledConditions,
    required this.currentIndex,
  });

  final String title;
  final List<String> shuffledConditions;
  final int currentIndex;
  final String userId;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final int _totalTime = 60; // 合計時間
  int _counter = 60; // 15分で初期化 => テストのため10秒で初期化
  late Timer _timer; // lateを使ってタイマー変数を宣言
  final backgroundPlayer = AudioPlayer(); // 実験音声用インスタンス
  final alarmPlayer = AudioPlayer(); // アラーム用インスタンス
  final Random _random = Random();

  DateTime? startTime; // タイマー開始時刻を保持
  DateTime? endTime; // タイマー終了時刻を保持

  final TextEditingController _answerController = TextEditingController();
  int _totalAnswered = 0; // 回答数
  int _correctCount = 0; // 正答数
  final List<TaskLogEntry> _taskLog = [];

  // 現在のタスク
  String _currentQuestion = '';
  int _currentAnswer = 0;
  String _currentLevel = 'Level 1'; // 現在の難易度レベル

  final _isTaskFinished = false;

  
  @override
  void initState() { // 初期化したい時に使用するメソッド
    super.initState();

    // 15分の音声再生を開始
    _playBackgroundAudio();
    _generateNewQuestion(); // 最初の問題生成
    startTime = DateTime.now();

    // 1秒ごとに実行されるタイマーを開始
    _timer = Timer.periodic(
      const Duration(seconds: 1), // 処理の実行時間
      (Timer timer) { // 実行する処理
        setState(() {
          _counter--; // _counter を１引く処理
          _updateDifficultyAndQuestion();

          if (_counter <= 0) {
          timer.cancel(); // カウントダウンが終了したらタイマーを止める
          _counter = 0;  // カウントがマイナスにならないようにする

          endTime = DateTime.now();

          // 時刻をサーバーに送信する
          // 成功・失敗にかかわらず、画面遷移は実行する
          _sendTimeToServer();

          _audioAndNavigator(); // タイマー終了時に通知音再生と画面遷移
          }
        });
      },
    );
  }

  // 経過時間に応じて難易度を更新し、新しい問題を生成する
  void _updateDifficultyAndQuestion() {
    final elapsedTime = _totalTime - _counter;

    String nextLevel;
    if (elapsedTime < 300) { // 5分未満
      nextLevel = 'Level 1';
    } else if (elapsedTime < 600) { // 5分以上10分未満
      nextLevel = 'Level 2';
    } else {
      nextLevel = 'Level 3';
    }

    // 難易度が変わった場合のみ新しい問題を生成
    if (_currentLevel != nextLevel) {
      _currentLevel = nextLevel;
      _generateNewQuestion();
    }
  }

  // 難易度に応じた問題生成ロジック
  void _generateNewQuestion() {
    int num1, num2, num3;
    String operator, question;
    int answer = 0;

    // 経過時間に応じた問題の生成
    switch (_currentLevel) {
      case 'Level 3':
      // Level 3: 三つの数字のタスク、または結果が負の数になる可能性がある計算
      if (_random.nextBool()) {
        // 三つの数字の計算
        num1 = _random.nextInt(20) + 1; // 1~20
        num2 = _random.nextInt(20) + 1;
        num3 = _random.nextInt(20) + 1; 
        
        List<String> ops = ['+', '-', '*']; // 3項演算では割り算は避ける
        String op1 = ops[_random.nextInt(ops.length)];
        String op2 = ops[_random.nextInt(ops.length)];

        question = '$num1 $op1 $num2 $op2 $num3';

        // 演算順序の計算
        int intermediate;
        switch (op1) {
          case '+': intermediate = num1 + num2; break;
          case '-': intermediate = num1 - num2; break;
          case '*': intermediate = num1 * num2; break;
          default: intermediate = 0;
        }

        switch (op2) {
          case '+': answer = intermediate + num3; break;
          case '-': answer = intermediate - num3; break;
          case '*': answer = intermediate * num3; break;
          default: answer = 0;
        }
      } else {
        // 負の数も含む可能性のある引き算/掛け算
        num1 = _random.nextInt(50) + 10; // 10~60
        num2 = _random.nextInt(50) + 1; // 1~50
        operator = _random.nextBool() ? '-' : '*';
        question = '$num1 $operator $num2';

        if (operator == '-') {
          answer = num1 - num2;
        } else {
          answer = num1 * num2;
        }
      }
      break;

    case 'Level 2':
      // Level 2: 四則演算（足し算、引き算、簡単な掛け算/割り算）
      num1 = _random.nextInt(50) + 10; // 10~59
      num2 = _random.nextInt(9) + 1; // 1~9

      List<String> ops = ['+', '-', '*', '/'];
      operator = ops[_random.nextInt(ops.length)];

      switch (operator) {
        case '+':
          answer = num1 + num2;
          break;
        case '-':
          // 結果が負にならないようにする
          if (num1 < num2) {
            int temp = num1;
            num1 = num2;
            num2 = temp;
          }
          answer = num1 - num2;
          break;
        case '*':
          // 積が大きくなりすぎないように調整
          num2 = _random.nextInt(5) + 1;
          answer = num1 * num2;
          break;
        case '/':
         // 割り切れる問題のみを生成
         int divisor = _random.nextInt(9) + 1;
         answer = _random.nextInt(9) + 1;
         num1 = divisor * answer;
         num2 = divisor;
         operator = '/';
         break;
        default:
          answer = 0;
      }
      question = '$num1 $operator $num2';
      break;

    case 'Level 1':
    default:
      // Level 1: シンプルな足し算
      num1 = _random.nextInt(80) + 10;
      num2 = _random.nextInt(9) + 1;
      question = '$num1 + $num2';
      answer = num1 + num2;
      _currentLevel = 'Level 1';
      break;
    }

    setState(() {
      _currentQuestion = question;
      _currentAnswer = answer;
      _answerController.clear();
    });
  }

  // 回答チェックとログ記録
  void _checkAnswer() {
    if (_isTaskFinished) return;

    final userAnswerText = _answerController.text.trim();

    if (userAnswerText.isEmpty) {
      // 未回答はスキップ
      return;
    }

    final int? userAnswer = int.tryParse(userAnswerText);
    final bool isCorrect = userAnswer != null && userAnswer == _currentAnswer;

    // ログを記録
    final entry = TaskLogEntry(
      question: _currentQuestion, 
      correctAnswer: _currentAnswer, 
      userAnswer: userAnswer,
      isCorrect: isCorrect, 
      timeStampSec: _totalTime - _counter, 
      difficultyLevel: _currentLevel,
    );
    _taskLog.add(entry);

    // メトリクスを更新
    _totalAnswered++;
    if (isCorrect) {
      _correctCount++;
    }

    _generateNewQuestion();
  }

  // 実験用音声を再生するメソッド
  void _playBackgroundAudio() async {
    // 15分の音声ファイルをセット
    await backgroundPlayer.setSource(AssetSource('audio/music_audio_2.wav'));
    await backgroundPlayer.resume();
  }

  // 実験用音声を停止し、アラームを鳴らして画面遷移するメソッド
  void _audioAndNavigator() async {
    // 実験用音声を停止
    await backgroundPlayer.stop();

    // アラーム音を再生
    await alarmPlayer.setSource(AssetSource('audio/alarm.mp3')); // 音声ファイル名
    await alarmPlayer.resume(); 

    alarmPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        final nextIndex = widget.currentIndex + 1;
        if (nextIndex < widget.shuffledConditions.length) {
          Navigator.pushReplacement(
          context,
            MaterialPageRoute(
              builder: (context) => RestScreen(
                title: '休憩時間',
                shuffledConditions: widget.shuffledConditions,
                currentIndex: widget.currentIndex + 1,
                userId: widget.userId,
              ),
            ),
          );
        } else {
          // 全てのタスクが終了したとき、ResultScreenへ遷移
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (context) => const ResultScreen(),
            ),
          );
        }
      }
    });
  }

  // ログ送信関数 (正答率を含むデータを送信)
  Future<void> _sendTimeToServer() async {
    const url = 'http://localhost:3000/api/experiment-log'; // サーバーのURL

    final accuracyRate = _totalAnswered > 0 ? (_correctCount / _totalAnswered) : 0.0;

    final data = {
      'user_id': widget.userId,
      'start_time': startTime!.toIso8601String(),
      'end_time': endTime!.toIso8601String(),
      'test_type': widget.title,
      // 現在の実験条件を設定
      'condition': widget.shuffledConditions[widget.currentIndex], 
      
      // 計算結果を送信
      'total_answered': _totalAnswered,
      'correct_count': _correctCount,
      'accuracy_rate': accuracyRate,
      'detailed_task_log': _taskLog.map((e) => e.toJson()).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: { 'Content-Type': 'application/json', },
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('ログ送信成功： ${response.body}');
      } else {
        debugPrint('ログ送信エラー: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('通信エラー: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // メモリリークを防ぐためにタイマーを破棄
    backgroundPlayer.stop();
    backgroundPlayer.dispose(); // AudioPlayerを破棄
    
    alarmPlayer.stop();
    alarmPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 秒数を見やすい形式に変換
    final int minutes = _counter ~/ 60; // 60で割った商（分）
    final int seconds = _counter % 60; // 60で割った余り（秒）
    String formattedTime = 
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} ($_currentLevel)'),
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
                  enabled: !_isTaskFinished,
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
              Text(
              '難易度： $_currentLevel',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          )
        )
      ),
    );
  }
}