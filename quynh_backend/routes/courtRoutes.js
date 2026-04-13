const express = require('express');
const router = express.Router();
const courtController = require('../controllers/courtController');

// Route to get all courts
router.get('/all', courtController.getAllCourts);

// Route to get a specific court by ID
router.get('/:id', courtController.getCourtById);

// Route to get courts by owner ID
router.get('/owner/:ownerId', courtController.getCourtsByOwner);

// Route to add a new court
router.post('/add', courtController.addCourt);

module.exports = router;
