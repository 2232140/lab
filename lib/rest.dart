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
  final int _totalTime = 10; // 合計時間（テストのため10秒）
  int _counter = 5; // 5分で初期化 => テストのため5秒で初期化
  late Timer _timer; // lateを使ってタイマー変数を宣言
  final player = AudioPlayer(); // AudioPlayerのインスタンスを作成

  @override
  void initState() { // 初期化したい時に使用するメソッド
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1), // 処理の実行時間
      (Timer timer) { // 実行する処理
        setState(() {
          _counter--; // _counter を１引く処理
          if (_counter <= 0) {
          timer.cancel(); // カウントダウンが終了したらタイマーを止める
          _counter = 0; // カウントがマイナスにならないようにする
          _playAudioAndNavigator(); // タイマー終了時に通知音再生と画面遷移
          }
        });
      },
    );
  }

  // 音声を再生し、画面を遷移させるメソッド
  void _playAudioAndNavigator() async {
    // 通知音を鳴らす
    await player.setSource(AssetSource('audio/alarm.mp3')); // 音声ファイル名
    await player.resume(); 

    player.onPlayerComplete.listen((_) {
      player.release();

      if (mounted) {
        // 次に遷移する画面をリストから決定
        int nextIndex = widget.currentIndex + 1;
        Widget nextScreen;
        String nextCondition;

        // 次の条件があるかチェック
        if (nextIndex < widget.shuffledConditions.length) {
          nextCondition = widget.shuffledConditions[nextIndex];
          if (nextCondition == 'breath') {
            nextScreen = BreathScreen(
              title: '呼吸法',
              shuffledConditions: widget.shuffledConditions,
              currentIndex: nextIndex,
            );
          } else if(nextCondition == 'affirmation') {
            nextScreen = AffirmationScreen(
              title: 'アファメーション',
              shuffledConditions: widget.shuffledConditions,
              currentIndex: nextIndex,
            );
          } else {
            nextScreen = MusicScreen(
              title: '音楽リラクゼーション',
              shuffledConditions: widget.shuffledConditions,
              currentIndex: nextIndex,
            );
          }
        } else {
          // 全ての条件が終了したら実験終了画面へ
          nextScreen = const ResultScreen();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // メモリリークを防ぐためにタイマーを破棄
    super.dispose();
    player.dispose(); // AudioPlayerを破棄
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