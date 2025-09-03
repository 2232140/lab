// 音楽リラクゼーションテストページ

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:expt/finish.dart';
import 'package:audioplayers/audioplayers.dart';

// タイマー画面
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key, required this.title});

  final String title;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final int _totalTime = 900; // 合計時間
  int _counter = 900; // 15分で初期化 => テストのため10秒で初期化
  late Timer _timer; // lateを使ってタイマー変数を宣言
  final backgroundPlayer = AudioPlayer(); // 実験音声用インスタンス
  final alarmPlayer = AudioPlayer(); // アラーム用インスタンス

  @override
  void initState() { // 初期化したい時に使用するメソッド
    super.initState();

    // 15分の音声再生を開始
    _playBackgroundAudio();

    // 1秒ごとに実行されるタイマーを開始
    _timer = Timer.periodic(
      const Duration(seconds: 1), // 処理の実行時間
      (Timer timer) { // 実行する処理
        setState(() {
          _counter--; // _counter を１引く処理
          if (_counter <= 0) {
          timer.cancel(); // カウントダウンが終了したらタイマーを止める
          _counter = 0;  // カウントがマイナスにならないようにする
          _audioAndNavigator(); // タイマー終了時に通知音再生と画面遷移
          }
        });
      },
    );
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

    // 音の再生が完了するのを待つ
    alarmPlayer.onPlayerComplete.listen((_) {
    // 再生が完了したら、AudioPlayerを解放
    alarmPlayer.release();
      
      // 画面遷移
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResultScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // メモリリークを防ぐためにタイマーを破棄
    backgroundPlayer.dispose(); // AudioPlayerを破棄
    alarmPlayer.dispose();
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