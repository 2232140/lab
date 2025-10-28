// アファメーションテストページ

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:expt/rest.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// タイマー画面
class AffirmationScreen extends StatefulWidget {
  const AffirmationScreen({
    super.key,
    required this.title,
    required this.shuffledConditions,
    required this.currentIndex,
  });

  final String title;
  final List<String> shuffledConditions;
  final int currentIndex;

  @override
  State<AffirmationScreen> createState() => _AffirmationScreenState();
}

class _AffirmationScreenState extends State<AffirmationScreen> {
  final int _totalTime = 10; // 合計時間
  int _counter = 10; // 15分で初期化 => テストのため10秒で初期化
  late Timer _timer; // lateを使ってタイマー変数を宣言
  final backgroundPlayer = AudioPlayer(); // 実験音声用インスタンス
  final alarmPlayer = AudioPlayer(); // アラーム用インスタンス

  DateTime? startTime;
  DateTime? endTime;

  // データをサーバーに送信する
  Future<void> _sendTimeToServer() async {
    const url = 'http://localhost:3000/api/experiment-log'; // サーバー側のURL

    // 送信するデータ
    final data = {
      // ユーザーを一意に認識するIDを追加
      'user_id': 'temporary_user_id',
      'condition': widget.shuffledConditions[widget.currentIndex],
      'start_time': startTime!.toIso8601String(),
      'end_time': endTime!.toIso8601String(),
      'test_type': widget.title,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // 成功：サーバーが正常にデータを受け付けた
          debugPrint('Time data successfully sent to server.');
        } else {
          // 失敗：サーバー側でエラーが発生した
          debugPrint('Faild to send data. Status code: ${response.statusCode}');
        }
    } catch (e) {
      // 通信エラー（ネットワークがないなど）
      debugPrint('Network error occurred: $e');
    }
  }

  @override
  void initState() { // 初期化したい時に使用するメソッド
    super.initState();
    // 15分の音声再生を開始
    _playBackgroundAudio();

    startTime = DateTime.now();

    _timer = Timer.periodic(
      const Duration(seconds: 1), // 処理の実行時間
      (Timer timer) { // 実行する処理
        setState(() {
          _counter--; // _counter を１引く処理
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

  // 実験用音声を再生するメソッド
  void _playBackgroundAudio() async {
    // 15分の音声ファイルをセット
    await backgroundPlayer.setSource(AssetSource('audio/affirmation_audio.mp3'));
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
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RestScreen(
              title: '休憩時間',
              shuffledConditions: widget.shuffledConditions,
              currentIndex: widget.currentIndex,
              userId: '001',
            ),
          ),
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
        child: Column( // ここをColumnに変更
          mainAxisAlignment: MainAxisAlignment.center, // 縦方向の中央寄せ
          children: [
            SizedBox( // StackをSizedBoxで囲む
              width: 200,
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progressValue),
                    duration: const Duration(milliseconds: 1000),
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
                ],
              ),
            ),
            const SizedBox(height: 20), // プログレスバーとテキストの間に少しスペースを空ける
            Text(
              'voice:VOICEVOX Nemo', // ここにクレジット表記を直接配置
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}