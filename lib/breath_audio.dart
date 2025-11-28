// 呼吸法テストページ

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
class BreathScreen extends StatefulWidget {
  const BreathScreen({
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
  State<BreathScreen> createState() => _BreathScreenState();
}

class _BreathScreenState extends State<BreathScreen> {
  final int _totalTime = 900; // 合計時間
  int _counter = 900; // 15分で初期化 => テストのため10秒で初期化
  late Timer _timer; // lateを使ってタイマー変数を宣言
  final backgroundPlayer = AudioPlayer(); // 実験音声用インスタンス
  final alarmPlayer = AudioPlayer(); // アラーム用インスタンス
  final Random _random = Random();

  DateTime? startTime;
  DateTime? endTime;


  final TextEditingController _answerController = TextEditingController();
  int _totalAnswered = 0; // 回答数
  int _correctCount = 0; // 正答数
  final List<TaskLogEntry> _taskLog = [];

  // 現在のタスク
  String _currentQuestion = '';
  int _currentAnswer = 0;
  String _currentLevel = 'Level 1'; // 現在の難易度レベル

  bool _isTaskFinished = false;

  Color _questionColor = Colors.black; // 数式の色
  Timer? _flashTimer; // 1分遅延用のタイマー

  // 問題ごとの時間制限設定
  final Map<String, int> _levelTimerLimits = const {
    'Level 1': 10,
    'Level 2': 15,
    'Level 3': 20,
  };

  int _questionLimit = 10; // 現在の問題の制限時間
  int _questionCounter = 10; // 現在の問題の残り時間
  Timer? _questionTimer; // 問題ごとのタイマー

  // 背景色と、色が変わる時間のリスト
  final List<Color> _backgroundColors = [
    Colors.yellow.shade100, // 600秒経過後
    Colors.orangeAccent.shade100, // 300秒経過後
  ];
  final List<int> _colorThresholds = [600, 300]; // 残り時間（秒）
  Color _currentBackgroundColor = Colors.white;

  @override
  void initState() { // 初期化したい時に使用するメソッド
    super.initState();

    // 15分の音声再生を開始
    _playBackgroundAudio();
    _generateNewQuestion(); // 最初の問題生成
    startTime = DateTime.now();
    _counter = _totalTime;

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
            _endTask();

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

  // 問題ごとのタイマーを開始する
  void _startQuestionTimer() {
    _questionTimer?.cancel();

    _questionLimit = _levelTimerLimits[_currentLevel] ?? 10;
    _questionCounter = _questionLimit;

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_questionCounter > 0) {
        setState(() {
          _questionCounter--;
        });
      } else {
        _questionTimer?.cancel();
        _handleQuestionTimeout();
      }
    });
  }

  // 問題の制限時間切れを処理する
  void _handleQuestionTimeout() {
    if (_isTaskFinished) return;
    _questionTimer?.cancel();

    // ログ記録
    final entry = TaskLogEntry(
      question: _currentQuestion, 
      correctAnswer: _currentAnswer, 
      userAnswer: null,
      isCorrect: false, 
      timeStampSec: _totalTime - _counter, 
      difficultyLevel: _currentLevel,
    );
    _taskLog.add(entry);

    _totalAnswered++; // 回数にカウント

    // 視覚的フィードバック
    setState(() {
      _questionColor = Colors.red;
    });

    // 1秒待ってから次の問題へ
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 1), () {
      _generateNewQuestion();
    });
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

        // 演算順序の優先度を取得
        int getPriority(String op) {
          if (op == '*' || op == '/') return 2;
          if (op == '+' || op == '-') return 1;
          return 0;
        }

        final p1 = getPriority(op1);
        final p2 = getPriority(op2);

        int intermediateResult = 0;

        // 優先順位が op1 >= op2 の場合
        if (p1 >= p2) {
          switch (op1) {
            case '+': intermediateResult = num1 + num2; break;
            case '-': intermediateResult = num1 - num2; break;
            case '*': intermediateResult = num1 * num2; break;
          }

          switch (op2) {
            case '+': answer = intermediateResult + num3; break;
            case '-': answer = intermediateResult - num3; break;
            case '*': answer = intermediateResult * num3; break;
            case '/': answer = intermediateResult ~/ num3; break;
          }
        } else { // 優先順位がop2 > op1 の場合
        switch (op2) {
          case '*': intermediateResult = num2 * num3; break;
          case '/': intermediateResult = num2 ~/ num3; break;
          default:intermediateResult = 0;
        }

        switch (op1) {
          case '+': answer = num1 + intermediateResult; break;
          case '-': answer = num1 - intermediateResult; break;
        }
      }
    }else {
      num1 = _random.nextInt(50) + 10; // 10~60
      num2 = _random.nextInt(50) + 1; // 1~50
      operator = _random.nextBool() ? '-' : '*';
      question = '$num1 $operator $num2';

      if (operator == '-') {
        answer = num1 -num2;
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
      // 常に色を黒に戻す
      _questionColor = Colors.black;
    });

    _flashTimer?.cancel();

    // 問題ごとのタイマーをスタート
    _startQuestionTimer();

    // 残り時間に応じて背景色を更新
    _updateBackgroundColor();
  }

  // 背景色を更新するメソッド
  void _updateBackgroundColor() {
    for (int i = 0; i < _colorThresholds.length; i++) {
      if (_counter >= _colorThresholds[i]) {
        // 残り時間が閾値以上の場合、その色に設定
        Color nextColor = _backgroundColors[i];
        if (_currentBackgroundColor != nextColor) {
          _currentBackgroundColor = nextColor;
        }
        break;
      }
    }
  }

  // 回答チェックとログ記録
  void _checkAnswer() {
    // キーボードを閉じる
    FocusScope.of(context).unfocus();

    if (_isTaskFinished) return;
    if (_flashTimer != null && _flashTimer!.isActive) return;

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

    if (isCorrect) {
      // 正解の場合：問題タイマーを停止し、すぐに次の問題へ
      _questionTimer?.cancel();
      _generateNewQuestion();
    } else {
      _questionTimer?.cancel();
      // 不正解の場合：問題タイマーを停止、赤色にして1秒待機してから次の問題へ
      setState(() {
        // 数式の色を赤に設定
        _questionColor = const Color(0xFFFF0000);
      });

      _flashTimer?.cancel();
      // 1秒後に次の問題へ移行
      _flashTimer = Timer(const Duration(seconds: 1), () {
        // _generateNewQuestion() の中で色も黒に戻り、UIがリセットされる
        _generateNewQuestion();
      });
    }
  }

  // 実験用音声を再生するメソッド
  void _playBackgroundAudio() async {
    // 15分の音声ファイルをセット
    await backgroundPlayer.setSource(AssetSource('audio/breath_audio.mp3'));
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

  // タスク終了処理
  void _endTask() async{
    if (_isTaskFinished) return;

    _timer.cancel();
    _questionTimer?.cancel();
    _isTaskFinished = true;
    endTime = DateTime.now();
    // アラームが鳴り終わるのを待つ
    await _playAlarm();

    await _sendTimeToServer(); // サーバーにログを送信

    if (!mounted) return;

    final nextIndex = widget.currentIndex + 1;
        
    // 次の実験条件をチェック
    if (nextIndex < widget.shuffledConditions.length) {
      // 次のタスクがある場合、RestScreenに遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RestScreen(
            title: '休憩時間',
            shuffledConditions: widget.shuffledConditions,
            currentIndex: nextIndex, // インデックスをインクリメントして渡す
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
          builder: (context) => const ResultScreen(), 
        ),
      );
    }
  }

  Future<void> _playAlarm() async {
    final completer = Completer<void>();

    // リスナーを設定し、再生が完了したらCompleterを完了させる
    alarmPlayer.onPlayerComplete.listen((event) {
        if (!completer.isCompleted) {
            completer.complete();
        }
    });

    await alarmPlayer.play(AssetSource('audio/alarm.mp3'));
    await completer.future;
  }

  // ログ送信関数 (正答率を含むデータを送信)
  Future<void> _sendTimeToServer() async {
    const url = 'http://192.168.11.26:3000/api/experiment-log'; // サーバーのURL

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
    _questionTimer?.cancel();
    _flashTimer?.cancel();
    backgroundPlayer.stop();
    backgroundPlayer.dispose(); // AudioPlayerを破棄
    
    alarmPlayer.stop();
    alarmPlayer.dispose();
    
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 秒数を見やすい形式に変換
    final int minutes = _counter ~/ 60; // 60で割った商（分）
    final int seconds = _counter % 60; // 60で割った余り（秒）
    String formattedTime = 
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // 点滅中はボタンを無効化
    final bool isInputEnabled = !_isTaskFinished && (_flashTimer == null || !_flashTimer!.isActive);

    // 問題の残り時間の進捗率を計算
    final double questionProgress = (_questionLimit > 0)
      ? _questionCounter / _questionLimit
      : 0.0;

    String displayQuestion =_currentQuestion
        .replaceAll('*', '×') // * を ×に変換
        .replaceAll('/', '÷'); // / を ÷に変換

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} ($_currentLevel)'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: _currentBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // タイマー表示
                Text(
                  '残り時間: $formattedTime 秒' ,
                  style: const TextStyle(fontSize: 24, color: Colors.red),
                ),

                const SizedBox(height: 20),

                // 問題ごとの制限時間表示とグラフ
                Text(
                  '問題制限時間: $_questionLimit秒（残り: $_questionCounter秒）',
                  style: const TextStyle(fontSize: 18, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 300,
                  child: LinearProgressIndicator(
                    value: questionProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      // 残り時間が少ないほど赤くする
                      questionProgress > 0.5 ? Colors.green : (questionProgress > 0.2 ? Colors.orange : Colors.red)
                    ),
                    minHeight: 15,
                  ),
                ),
                const SizedBox(height: 40),

                // 問題表示
                Text(
                  displayQuestion,
                  style: TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.bold,
                    color: _questionColor,
                  ),
                ),
                const SizedBox(height: 30),

                // 解答入力欄
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _answerController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                    decoration: const InputDecoration(
                      hintText: '答えを入力',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _checkAnswer(), // Enterキーでチェック
                    enabled: isInputEnabled,
                  ),
                ),
                const SizedBox(height: 30),

                // 回答ボタン
                ElevatedButton(
                  onPressed: isInputEnabled ? _checkAnswer : null, 
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
      )
    );
  }
}