// 休憩時間ページ

import 'package:expt/breath_audio.dart';
import 'package:flutter/material.dart';
import 'package:expt/affirmation_audio.dart';
import 'package:expt/music_audio.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

// タイマー画面
class RestScreen extends StatefulWidget {
  const RestScreen({super.key, required this.title});

  final String title;

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  // 画面遷移の回数をカウントするための静的変数
  static int _transitionCount = 0;

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

    // 音声の再生後に画面を遷移
    // 現在の画面を置き換えることで、戻るボタンで前の画面に戻れなくする
    _transitionCount++; // 遷移回数を増やす
    Widget nextScreen;

    if (_transitionCount == 1) {
      nextScreen = const BreathScreen(title: '呼吸法');
    } else if (_transitionCount == 2) {
      nextScreen = const AffirmationScreen(title: 'アファメーション');
    } else {
      nextScreen = const MusicScreen(title: '音楽リラクゼーション');
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
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