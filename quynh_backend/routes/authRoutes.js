const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/upgrade-to-owner', authController.upgradeToOwner);
router.post('/update-password', authController.updatePassword);
router.get('/get-owners', authController.getOwners);

module.exports = router;
