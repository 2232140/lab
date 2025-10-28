const mongoose = require('mongoose');

const LogSchema = new mongoose.Schema({
    // flutterアプリから送られてくるデータに対応
    user_id: { type: String, required: true },
    condition: { type: String, required: false },
    test_type: {type: String, required: false },
    start_time: { type: String, required: true },
    end_time: { type: String, required: true },

    // 四則演算タスクの結果
    total_answered: { type: Number, required: false }, // 回答数
    correct_count: { type: Number, required: false }, // 正答数
    accuracy_rate: { type: Number, required: false }, // 正答率

    // サーバーが受け取った時間も記録する
    receiveAt: { type: Date, default: Date.now }
});

// モデルを作成し、エクスポート
const Log = mongoose.model('log', LogSchema);

module.exports = Log;