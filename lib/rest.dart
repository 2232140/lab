// 休憩時間ページ

import 'package:expt/breath_audio.dart';
import 'package:flutter/material.dart';
import 'package:expt/affirmation_audio.dart';
import 'package:expt/music_audio.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:expt/finish.dart';

// タイマー画面
class RestScreen extends StatefulWidget {
  const RestScreen({
    super.key, 
    required this.title,
    required this.shuffledConditions,
    required this.currentIndex,
    required this.userId,
  });

  final String title;
  final List<String> shuffledConditions;
  final int currentIndex;
  final String userId;

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  final int _totalTime = 300; // 合計時間（テストのため10秒）
  int _counter = 300; // 5分で初期化 => テストのため5秒で初期化
  late Timer _timer; // lateを使ってタイマー変数を宣言
  
  // 致命的バグ修正 1: AudioPlayerをlateで宣言し、initStateで初期化する
  late final AudioPlayer player; 

  @override
  void initState() { // 初期化したい時に使用するメソッド
    super.initState();
    
    // ✨ 致命的バグ修正 1: initState内で AudioPlayer を安全に初期化
    player = AudioPlayer(); 

    _timer = Timer.periodic(
      const Duration(seconds: 1), // 処理の実行時間
      (Timer timer) { // 実行する処理
        setState(() {
          _counter--; // _counter を１引く処理
          if (_counter <= 0) {
            _timer.cancel(); // タイマー停止
            
            // アラーム音再生ロジック (クラッシュ防止のため try-catch を追加)
            try {
              player.setVolume(1.0);
              // アラーム音のファイル名はご自身の環境に合わせて修正してください
              player.play(AssetSource('audio/alarm.mp3')); 
            } catch (e) {
              print('Alarm playback error (safe): $e');
            }
            
            // 次の画面へ遷移
            if (widget.currentIndex < widget.shuffledConditions.length - 1) {
              final nextIndex = widget.currentIndex + 1;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => _getNextScreen(
                    widget.userId,
                    widget.shuffledConditions[nextIndex],
                    widget.shuffledConditions,
                    nextIndex,
                  ),
                ),
              );
            } else {
              // 全ての条件が終了したらFinishへ
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResultScreen(),
                ),
              );
            }
          }
        });
      },
    );
  }

  // 休憩後のタスク画面を決定するロジック (no_audio.dartにもあるはず)
  Widget _getNextScreen(String userId, String title, List<String> conditions, int index) {
    switch (title) {
      case '呼吸法':
        return BreathScreen(userId: userId, title: title, shuffledConditions: conditions, currentIndex: index);
      case 'アファメーション':
        return AffirmationScreen(userId: userId, title: title, shuffledConditions: conditions, currentIndex: index);
      case '音楽リラクゼーション':
        return MusicScreen(userId: userId, title: title, shuffledConditions: conditions, currentIndex: index);
      default: // 無条件 (便宜上BreathScreenにフォールバック)
        // ここは実際の無条件タスクのクラス（例: ArithmeticTaskScreen）を返す必要があります
        return BreathScreen(userId: userId, title: title, shuffledConditions: conditions, currentIndex: index); 
    }
  }

  @override
  void dispose() {
    // 順序はあなたの修正で完璧です
    player.dispose(); // AudioPlayerを解放
    _timer.cancel(); // タイマーを破棄

    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    // 秒数を見やすい形式に変換
    String formattedTime = "${(_counter ~/ 60).toString().padLeft(2, '0')}:${(_counter % 60).toString().padLeft(2, '0')}";

    // プログレスバーの値
    double progressValue = (_totalTime - _counter) / _totalTime;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progressValue),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                  );
                },
              ),
              Center(
                child: Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}