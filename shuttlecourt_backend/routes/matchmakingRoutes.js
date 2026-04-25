const express = require('express');
const router = express.Router();
const matchmakingController = require('../controllers/matchmakingController');

// Route lấy tất cả kèo ghép
router.get('/all', matchmakingController.getAllMatches);

// Route tạo kèo ghép mới
router.post('/create', matchmakingController.createMatch);

// Đăng ký yêu cầu tham gia (User B -> User A)
router.post('/join', matchmakingController.requestJoinMatch);

// Phản hồi yêu cầu tham gia (User A -> User B)
router.post('/respond', matchmakingController.respondToJoinRequest);

module.exports = router;
