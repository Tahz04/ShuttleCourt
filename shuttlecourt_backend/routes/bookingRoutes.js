const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');

router.post('/', bookingController.createBooking);
router.get('/user/:user_id', bookingController.getBookingsByUser);
router.get('/owner/:ownerId', bookingController.getBookingsByOwner);
router.get('/all', bookingController.getAllBookings);
router.get('/booked-slots', bookingController.getBookedSlots);
router.put('/:id/status', bookingController.updateBookingStatus);

router.post('/:id/cancel', bookingController.cancelBooking);
module.exports = router;
