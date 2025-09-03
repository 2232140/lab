// 無条件テストページ
// 後で通知音をつける

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:expt/rest.dart';
import 'package:audioplayers/audioplayers.dart';

// タイマー画面
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, required this.title});

  final String title;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final int _totalTime = 10; // 合計時間
  int _counter = 10; // 15分で初期化 => テストのため10秒で初期化
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
          _counter = 0;  // カウントがマイナスにならないようにする
          _playAudioAndNavigator(); // タイマー終了時に通知音再生と画面遷移
          }
        });
      },
    );
  }

  // 音を鳴らして画面遷移させる
  void _playAudioAndNavigator() async {
    // ローカルセットアップの音声を再生
    await player.setSource(AssetSource('audio/alarm.mp3')); // 音声ファイル名
    await player.resume(); 

    // 音の再生が完了するのを待つ
    player.onPlayerComplete.listen((_) {
      // 再生したら、AudioPlayerを解放
      player.release();

      // 画面遷移
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RestScreen(title: '休憩時間')),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // メモリリークを防ぐためにタイマーを破棄
    player.dispose(); // AudioPlayerを破棄
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 秒数を見やすい形式に変換
    String formattedTime = "${(_counter ~/ 60).toString().padLeft(2, '0')}:${(_counter % 60).toString().padLeft(2, '0')}";

    // プログレスバーの値（0.0から1.0）
    double progressValue = (_totalTime - _counter) / _totalTime;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
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
                }
              ),
              Center(
                child: Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}