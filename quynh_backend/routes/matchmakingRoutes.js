const express = require('express');
const router = express.Router();
const matchmakingController = require('../controllers/matchmakingController');

// Route lấy tất cả kèo ghép
router.get('/all', matchmakingController.getAllMatches);

// Route tạo kèo ghép mới
router.post('/create', matchmakingController.createMatch);

module.exports = router;
