const express = require('express');
const router = express.Router();
const courtController = require('../controllers/courtController');

router.get('/all', courtController.getAllCourts);
router.get('/:id', courtController.getCourtById);
router.get('/owner/:ownerId', courtController.getCourtsByOwner);
router.post('/add', courtController.addCourt);
router.put('/update/:id', courtController.updateCourt);
router.delete('/delete/:id', courtController.deleteCourt);
router.post('/maintenance/:id', courtController.toggleMaintenance);

module.exports = router;
