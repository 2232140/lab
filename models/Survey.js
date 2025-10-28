const mongoose = require('mongoose');

const SurveySchema = new mongoose.Schema({
    // 実験ログとの関連付けに使用
    user_id: {
        type: String,
        required: true,
        index: true
    },

    // アンケートデータ
    answers: {
        type: mongoose.Schema.Types.Mixed,
        required: true
    },

    // 自由記述欄
    additional_feedback: {
        type: String
    },

    // サーバーが受け取った時間
    receiveAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true // 作成日時と更新日時を自動で追加
});

// モデルを作成し、エクスポート
const Survey = mongoose.model('Survey', SurveySchema);

module.exports = Survey;