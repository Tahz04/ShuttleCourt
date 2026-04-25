const express = require('express');
const router = express.Router();
const ownerRequestController = require('../controllers/ownerRequestController');

router.post('/submit', ownerRequestController.submitRequest);
router.get('/all', ownerRequestController.getAllRequests);
router.put('/approve/:requestId', ownerRequestController.approveRequest);

module.exports = router;
