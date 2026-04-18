const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');

// Create a review
router.post('/', reviewController.createReview);

// Get all reviews for a specific court
router.get('/court/:courtId', reviewController.getCourtReviews);

// Get all reviews submitted by a specific user
router.get('/user/:userId', reviewController.getUserReviews);

module.exports = router;
