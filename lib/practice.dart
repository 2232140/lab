// 呼吸法練習用ページ

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();
const audioPath = 'audio/practice.mp3';

class  PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  // 戻るボタン
  back(BuildContext context) {
    // 前の画面に戻る
    context.pop();
  }

  void _stopAudio() async {
    await player.stop();
  }

  @override
  Widget build(BuildContext context) {
    // 画面の上に表示するバー
    final appBar = AppBar(
      backgroundColor: Colors.blue,
      title: const Text('呼吸法練習ページ'),
    );

    // 戻るボタン
    final backButton = ElevatedButton(
      onPressed: () => back(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      child: const Text('< 戻る'),
    );

    // ホーム画面に戻る
    final homebutton = ElevatedButton(
      onPressed: () {
        context.go('/a');
      }, 
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      child: const Text('ホーム画面へ'),
    );

    // 音声再生ボタン
    final audiobutton = ElevatedButton(
      onPressed: () {
        player.play(AssetSource(audioPath));
      },
      child: Text('音声を再生する'),
    );

    // 音声停止ボタン
    final stopbutton = ElevatedButton(
      onPressed: _stopAudio,
      child: Text('音声を停止する'),
    );

    // 画面全体
    return Scaffold(
      appBar: appBar,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              '音声を再生し、指示に従ってください。\n問題ない場合は、ホーム画面に戻ってお待ちください。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
              ),
            ),
            audiobutton,
            stopbutton,
            Text('voice:VOICEVOX Nemo'),
            backButton,
            homebutton,
          ],
        ),
      ),
    );
  }
}