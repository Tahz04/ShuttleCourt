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
// Get reviews for all courts owned by a specific owner
exports.getOwnerReviews = async (req, res) => {
    try {
        const ownerId = req.params.ownerId;
        const [reviews] = await db.execute(
            `SELECT r.*, u.full_name as user_name, c.name as court_name 
             FROM reviews r 
             JOIN users u ON r.user_id = u.id 
             JOIN courts c ON r.court_id = c.id 
             WHERE c.owner_id = ? 
             ORDER BY r.created_at DESC`,
            [ownerId]
        );
        res.json({ success: true, reviews });
    } catch (error) {
        console.error('Error fetching owner reviews:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Get all reviews (for Admin)
exports.getAllReviews = async (req, res) => {
    try {
        const [reviews] = await db.execute(
            `SELECT r.*, u.full_name as user_name, c.name as court_name, o.full_name as owner_name 
             FROM reviews r 
             JOIN users u ON r.user_id = u.id 
             JOIN courts c ON r.court_id = c.id 
             JOIN users o ON c.owner_id = o.id
             ORDER BY r.created_at DESC`
        );
        res.json({ success: true, reviews });
    } catch (error) {
        console.error('Error fetching all reviews:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Owner replies to a review
exports.replyToReview = async (req, res) => {
    try {
        const reviewId = req.params.id;
        const { reply } = req.body;
        
        if (!reply) {
            return res.status(400).json({ success: false, message: 'Reply content is required' });
        }

        await db.execute(
            'UPDATE reviews SET owner_reply = ?, owner_reply_at = CURRENT_TIMESTAMP WHERE id = ?',
            [reply, reviewId]
        );
        
        res.json({ success: true, message: 'Reply added successfully' });
    } catch (error) {
        console.error('Error replying to review:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Owner reports a review to Admin
exports.reportReview = async (req, res) => {
    try {
        const reviewId = req.params.id;
        const { ownerId, reason } = req.body;

        if (!ownerId) {
            return res.status(400).json({ success: false, message: 'Missing ownerId' });
        }

        const [reviewRows] = await db.execute(
            `SELECT r.id, c.owner_id
             FROM reviews r
             JOIN courts c ON r.court_id = c.id
             WHERE r.id = ?`,
            [reviewId]
        );

        if (reviewRows.length === 0) {
            return res.status(404).json({ success: false, message: 'Review not found' });
        }

        if (reviewRows[0].owner_id !== Number(ownerId)) {
            return res.status(403).json({ success: false, message: 'Forbidden' });
        }

        const [existing] = await db.execute(
            `SELECT id FROM review_reports WHERE review_id = ? AND status = 'pending'`,
            [reviewId]
        );

        if (existing.length > 0) {
            return res.status(400).json({ success: false, message: 'Report already submitted' });
        }

        await db.execute(
            `INSERT INTO review_reports (review_id, owner_id, reason, status)
             VALUES (?, ?, ?, 'pending')`,
            [reviewId, ownerId, reason || null]
        );

        const [admins] = await db.execute("SELECT id FROM users WHERE role = 'admin'");
        for (const admin of admins) {
            await db.execute(
                `INSERT INTO notifications (user_id, title, message, type)
                 VALUES (?, ?, ?, ?)`,
                [
                    admin.id,
                    '⚠️ Báo cáo đánh giá',
                    'Chủ sân vừa báo cáo một đánh giá cần xử lý.',
                    'review_report'
                ]
            );
        }

        res.json({ success: true, message: 'Report submitted' });
    } catch (error) {
        console.error('Error reporting review:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Admin: get reported reviews (pending)
exports.getReviewReports = async (req, res) => {
    try {
        const [rows] = await db.execute(
            `SELECT rr.id AS report_id, rr.reason, rr.status, rr.created_at AS reported_at,
                    r.*, u.full_name AS user_name, c.name AS court_name, c.owner_id, o.full_name AS owner_name
             FROM review_reports rr
             JOIN reviews r ON rr.review_id = r.id
             JOIN users u ON r.user_id = u.id
             JOIN courts c ON r.court_id = c.id
             JOIN users o ON c.owner_id = o.id
             WHERE rr.status = 'pending'
             ORDER BY rr.created_at DESC`
        );
        res.json({ success: true, reports: rows });
    } catch (error) {
        console.error('Error fetching review reports:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Admin: resolve a report (delete or keep)
exports.resolveReviewReport = async (req, res) => {
    try {
        const reportId = req.params.reportId;
        const { action, adminId } = req.body;

        if (!action || (action !== 'delete' && action !== 'keep')) {
            return res.status(400).json({ success: false, message: 'Invalid action' });
        }

        const [reports] = await db.execute(
            `SELECT id, review_id, status FROM review_reports WHERE id = ?`,
            [reportId]
        );

        if (reports.length === 0) {
            return res.status(404).json({ success: false, message: 'Report not found' });
        }

        if (reports[0].status !== 'pending') {
            return res.status(400).json({ success: false, message: 'Report already resolved' });
        }

        if (action === 'delete') {
            await db.execute('DELETE FROM reviews WHERE id = ?', [reports[0].review_id]);
        }

        await db.execute(
            `UPDATE review_reports
             SET status = 'resolved', action = ?, resolved_at = CURRENT_TIMESTAMP, resolved_by = ?
             WHERE id = ?`,
            [action, adminId || null, reportId]
        );

        res.json({ success: true, message: 'Report resolved' });
    } catch (error) {
        console.error('Error resolving review report:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
