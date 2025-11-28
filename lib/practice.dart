// 呼吸法練習用ページ

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

const audioPath = 'audio/audio_practice.mp3';

class  PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState(); 
}

class _PracticePageState extends State<PracticePage> { 
  // 3. AudioPlayerをStateクラス内に移動
  final player = AudioPlayer(); 

  back(BuildContext context) {
    // 前の画面に戻る
    context.pop();
  }

  void _stopAudio() async {
    await player.stop();
  }
  
  // 4. dispose()を追加して解放 (順序は完璧です)
  @override
  void dispose() {
    player.dispose(); 
    super.dispose();
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
      onPressed: () async { // ✨ 修正: asyncを追加
        try {
          await player.play(AssetSource(audioPath)); // ✨ 修正: try-catchで再生を保護
        } catch (e) {
          print('Audio playback error (safe): $e');
        }
      },
      child: const Text('音声を再生する'),
    );

    // 音声停止ボタン
    final stopbutton = ElevatedButton(
      onPressed: _stopAudio,
      child: const Text('音声を停止する'),
    );

    // 画面全体
    return Scaffold(
      appBar: appBar,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              '音声を再生し、指示に従ってください。\\n問題ない場合は、ホーム画面に戻ってお待ちください。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
              ),
            ),
            audiobutton,
            stopbutton,
            const Text('voice:VOICEVOX Nemo'),
            Row( // 戻る/ホームボタンを横並びに
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                backButton,
                homebutton,
              ]
            )
          ],
        )
      )
    );
  }
}