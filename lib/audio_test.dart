// 音声テスト用ページ

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';

const audioPath = 'audio/Audio_test.mp3';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState(); 
}

// ✨ 致命的バグ修正 2: インデントを削除して左端に配置
class _TestPageState extends State<TestPage> { 
  // 3. AudioPlayerをStateクラス内に移動
  final player = AudioPlayer(); 

  // 進むボタンを押した時 (WidgetからStateへアクセス)
  push(BuildContext context) {
    context.push('/c');
  }

  // 戻るボタンを押した時
  back(BuildContext context) {
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
    // ボタン
    final button = ElevatedButton(
      // ボタンを押したら、音声を再生する
      onPressed: () async { // ✨ 修正: asyncを追加
        try {
          await player.play(AssetSource(audioPath)); // ✨ 修正: try-catchで再生を保護
        } catch (e) {
          print('Audio playback error (safe): $e');
        }
      },
      child:const Text('音声を再生する'),
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
      child: const Text('音声を停止する'),
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
        const Text(
          '下のボタンを押し、音量の調節を行ってください。\\n音声の再生が終わったら、次のページに進んでください。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
          ),
        ),
        button,
        stopbutton,
        const Text('voice:VOICEVOX Nemo'),
        row,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('音声テスト'),
      ),
      body: Center(
        child: col,
      ),
    );
  }
}