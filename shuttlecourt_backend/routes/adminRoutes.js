const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

router.get('/dashboard-stats', adminController.getDashboardStats);
router.get('/users', adminController.getAllUsers);
router.put('/users/:id/toggle-lock', adminController.toggleUserLock);

module.exports = router;
