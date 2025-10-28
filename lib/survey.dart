import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 質問と選択肢のデータモデル
class QuestionData {
  final String questionText;
  final List<String> options;
  final String key;

  QuestionData(this.questionText, this.options, this.key);
}

class SectionData {
  final String title;
  final List<QuestionData> questions;

  SectionData(this.title, this.questions);
}

// アンケートの質問リスト
final List<SectionData> _sections = [
  SectionData(
    '①【呼吸法】について',
    [
      QuestionData(
        'Q1.質問内容', 
        ['大変満足', '満足', '不満'],
        's1_breathing_effect',
      ),
      QuestionData(
        'Q2.質問内容', 
        ['大変満足', '満足', '不満'],
        's1_brething_clarity',
      ),
    ]
  ),
  SectionData(
    '【アファメーション】について',
    [
      QuestionData(
        'Q1.質問内容', 
        ['大変満足', '満足', '不満'],
        's2_affirmation_effect'
      ),
    ]
  ),
  SectionData(
    '【音楽リラクゼーション】について', 
    [
      QuestionData(
        'Q1.質問内容', 
        ['大変満足', '満足', '不満'],
        's3_music_effect'
      ),
    ]
  )
];

class SurveyScreen extends StatefulWidget {
  final String userId;
  const SurveyScreen({super.key, required this.userId});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // 質問のインデックスとその回答（選択肢の文字列）を保持するMap
  final Map<String, String> _answers = {};

  // 自由記述欄のコントローラー
  final TextEditingController _feedbackController = TextEditingController();

  // 送信中かどうかを管理する状態
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // ラジオボタンで選択肢を選択した時の処理
  void _handleOptionChange(String questionIndex, String? selectedOption) {
    setState(() {
      // 選択された値をMapに保存
      _answers[questionIndex] = selectedOption!;
    });
  }

  // データベースへの送信
  Future<void> _sendDataToDatabase(Map<String, dynamic> surveyData) async {
    // サーバーの新しいエンドポイントを指定
    const String apiUrl = 'http://localhost:3000/api/submit-survey';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // MapデータをJSON文字列に変換して送信
      body: jsonEncode(surveyData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('アンケートデータをサーバーに正常送信');
    } else {
      print('サーバー応答エラー: ${response.statusCode}');
      print('エラー詳細: ${response.body}');
      throw Exception('サーバーへのデータ送信に失敗しました (${response.statusCode})');
    }
  }

  // フォーム送信処理
  void _submitSurvey() async {
    // 必須回答のチェック
    int totalQuestions = _sections.fold(0, (sum, section) => sum + section.questions.length);
    if (_answers.length < totalQuestions) {
      // 未回答の質問がある場合の処理
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未回答の質問があります。すべて回答してください。')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // データをMapとして構造化
    Map<String, dynamic> dataToSend = {};
    dataToSend['user_id'] = widget.userId;

    // ラジオボタンの回答を構造化
    dataToSend.addAll(_answers);

    // 自由記述の回答を追加
    dataToSend['additional_feedback'] = _feedbackController.text;
    dataToSend['user_id'] = 'user_001';

    // データベースへの送信を試行
    try {
      await _sendDataToDatabase(dataToSend);

      // 送信成功時のダイアログ表示
      if (!mounted) return;
      showDialog(
        context: context, 
        builder: (context) {
          return AlertDialog(
            title: const Text('送信完了'),
            content: const Text('アンケートにご協力いただきありがとうございました。'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                }, 
                child: const Text('閉じる'),
              ),
            ],
          );
        }
      ); 
    } catch (e) {
      // エラー時の処理
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送信中にエラーが発生しました： $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主観アンケート'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 質問のリストを作成
            ..._sections.expand((section) {
              return [
                // 大問タイトル
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                // その大問に含まれる質問リスト
                ...section.questions.map((question) {
                  return _buildQuestionCard(question);
                }),
              ];
            }),

            // 自由記述欄の追加
            _buildFreeformField(),

            const SizedBox(height: 32.0),

            // 送信ボタン
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: _isSubmitting
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : const Text(
                    'アンケートを送信',
                    style: TextStyle(color: Colors.white),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // 質問カードウィジェット
  Widget _buildQuestionCard(QuestionData question) {
    // 現在選択されている回答の値
    final selectedOption = _answers[question.key];

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 質問文
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            // 選択のリスト
            ...question.options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                // このラジオボタンの値
                value: option,
                // グループ内で現在選択されている値
                groupValue: selectedOption,
                // 選択時のコールバック
                onChanged: (String? value) {
                  _handleOptionChange(question.key, value);
                },
                activeColor: Colors.teal,
              );
            }),
          ],
        ),
      ),
    );
  }

  // 自由記述欄ウィジェット
  Widget _buildFreeformField() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Q7.何か気付いた点があればご記入ください。',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const Divider(height: 20, thickness: 1),
          TextFormField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'ここに自由な意見を入力してください。',
              border: OutlineInputBorder(),
            ),
          )
        ],
      ),
    );
  }
}

// main.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Survey Demo',
      home: SurveyScreen(),
    );
  }
}