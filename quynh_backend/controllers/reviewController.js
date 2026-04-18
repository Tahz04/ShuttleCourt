const db = require('../config/database');

// Create a review
exports.createReview = async (req, res) => {
    try {
        const { court_id, user_id, booking_id, rating, comment, photos } = req.body;
        
        if (!court_id || !user_id || !rating) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        const photosJson = photos ? JSON.stringify(photos) : null;
        
        const [result] = await db.execute(
            'INSERT INTO reviews (court_id, user_id, booking_id, rating, comment, photos) VALUES (?, ?, ?, ?, ?, ?)',
            [court_id, user_id, booking_id || null, rating, comment || null, photosJson]
        );
        
        res.status(201).json({ success: true, message: 'Review added successfully', reviewId: result.insertId });
    } catch (error) {
        console.error('Error creating review:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Get reviews for a specific court
exports.getCourtReviews = async (req, res) => {
    try {
        const courtId = req.params.courtId;
        const [reviews] = await db.execute(
            `SELECT r.*, u.full_name as user_name 
             FROM reviews r 
             JOIN users u ON r.user_id = u.id 
             WHERE r.court_id = ? 
             ORDER BY r.created_at DESC`,
            [courtId]
        );

        // Calculate average rating
        let averageRating = 0;
        if (reviews.length > 0) {
            const sum = reviews.reduce((acc, current) => acc + current.rating, 0);
            averageRating = (sum / reviews.length).toFixed(1);
        }

        res.json({ success: true, reviews, averageRating, total: reviews.length });
    } catch (error) {
        console.error('Error fetching reviews:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Get reviews by a specific user (for the user's history/profile)
exports.getUserReviews = async (req, res) => {
    try {
        const userId = req.params.userId;
        const [reviews] = await db.execute(
            `SELECT r.*, c.name as court_name 
             FROM reviews r 
             JOIN courts c ON r.court_id = c.id 
             WHERE r.user_id = ? 
             ORDER BY r.created_at DESC`,
            [userId]
        );
        res.json({ success: true, reviews });
    } catch (error) {
        console.error('Error fetching user reviews:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
