const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const Log = require('./models/Log');
const Survey = require('./models/Survey');

const app = express();
const PORT = 3000; // ポート番号

// ミドルウェア
// Flutterアプリからのリクエストを許可
app.use(cors());

// JSON形式のリクエストボディを解析する
app.use(express.json());
app.use(bodyParser.json());

// MongoDB接続
const mongoUri = 'mongodb://localhost:27017/garmin_experiment_db'; // データベース名

mongoose.connect(mongoUri, {})
    .then(() => console.log('MongoDBに接続しました'))
    .catch(err => console.error('MongoDB接続エラー:' , err));

// 実験ログを受け取るPOSTエンドポイント
// Flutterのコードで使用したURL: http://localhost:3000/api/experiment-log
app.post('/api/experiment-log', async (req, res) => {
    try{
        const { user_id, condition, test_type, start_time, end_time, total_answered, correct_count, accuracy_rate } = req.body;

        // データが不足していないかチェック
        if(!user_id || !start_time || !end_time) {
        return res.status(400).send({ message: 'Missing require firlds.'});
        }

        // 新しいログドキュメントを作成
        const newLog = new Log({
            user_id,
            condition,
            test_type,
            start_time: start_time, 
            end_time: end_time,
            total_answered,
            correct_count,
            accuracy_rate,
            receiveAt: new Date(Date.now() + 9 * 60 * 60 * 1000),
        });

        // データベースに保存
        await newLog.save();

        /*
        // ログ出力（JSTで確認）
        const jstStartTime = newLog.start_time.toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' });
        const jstEndTime = newLog.end_time.toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' });
        const jstReceiveAt = newLog.receiveAt.toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' });

        console.log(`ログを保存しました： ${newLog.user_id} (${newLog.test_type})`);
        console.log(`  JST 開始時刻: ${jstStartTime}`);
        console.log(`  JST 終了時刻: ${jstEndTime}`);
        console.log(`  JST 受信時刻: ${jstReceiveAt}`);

        //console.log('ログを保存しました：', newLog);
        */
        // 成功レスポンスをFlutterに返す
        res.status(201).send({ message: 'Log recorded successfully', log: newLog});
        } catch (error) {
        console.error('ログ保存エラー：', error);

        if (error.name == 'ValidationError') {
            console.error('Mongoose Validation Error Details:');
            for (let field in error.errors) {
                console.error(`  - フィールド: ${field}, メッセージ: ${error.errors[field].message}`); // ここを修正
            }
        }
        res.status(500).send({ message: 'Internal server error', error: error.message});
    }
});

// アンケート結果を受け取るPOSTエンドポイント
app.post('/api/submit-survey', async (req, res) => {
    try {
        const { user_id, additional_feedback, ...answers } = req.body;

        if(!user_id) {
            return res.status(400).send({ message: 'User ID is required.'});
        }

        // MongoDBのモデルを使って新しいドキュメントを作成
        const newSurvey = new Survey({
            user_id,
            answers: answers,
            additional_feedback: additional_feedback,
            receiveAt: new Date(Date.now() + 9 * 60 * 60 * 1000),
        });

        // データベースに保存
        await newSurvey.save();

        console.log('アンケート結果を保存しました: User ID ${newSurvey.user_id}');
        // 成功レスポンスをFlutterに返す
        res.status(201).send({ message: 'Survey record successfully', survedId: newSurvey._id});
    } catch (error) {
        console.error('アンケート保存エラー: ', error);
        res.status(500).send({ message: 'Internal server error', error: error.message});
    }
});

// サーバー起動
app.listen(PORT, () => {
    console.log('サーバーがポート ${PORT} で起動しました');
    console.log('Flutterからのアクセスを待機しています・・・');
});