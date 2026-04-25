const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');

router.post('/', bookingController.createBooking);
router.get('/user/:user_id', bookingController.getBookingsByUser);
router.get('/all', bookingController.getAllBookings);
router.put('/:id/status', bookingController.updateBookingStatus);

module.exports = router;