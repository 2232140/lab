// 音声テスト用ページ

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';

final player = AudioPlayer();
const audioPath = 'audio/Audio_test.mp3';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  // 進むボタンを押した時
  push(BuildContext context) {
    // 呼吸法練習画面に進む
    context.push('/c');
  }

  // 戻るボタンを押した時
  back(BuildContext context) {
    // 前の画面に戻る
    context.pop();
  }

  void _stopAudio() async {
    await player.stop();
  }

  @override
  Widget build(BuildContext context) {
    // ボタン
    final button = ElevatedButton(
      // ボタンを押したら、音声を再生する
      onPressed: () {
        player.play(AssetSource(audioPath));
      },
      child:Text('音声を再生する'),
    );

    // 進むボタン
    final goButton = ElevatedButton(
      onPressed: () => push(context), 
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      child: const Text('進む >'),
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

    // 音声停止ボタン
    final stopbutton = ElevatedButton(
      onPressed: _stopAudio,
      child: Text('音声を停止する'),
    );

    // ボタンを横に並べる
    final  row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        backButton,
        goButton,
      ],
    );

    // 縦に並べるカラム
    final col = Column(
     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          '下のボタンを押し、音量の調節を行ってください。\n音声の再生が終わったら、次のページに進んでください。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
          ),
        ),
        button,
        stopbutton,
        Text('voice:VOICEVOX Nemo'),
        row,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声確認用ページ'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: col,
      ),
    );
  }
}