const db = require('../config/database');

exports.createBooking = async (req, res) => {
    try {
        const {
            user_id,
            court_name,
            court_address,
            slot,
            booking_date,
            price,
            payment_method
        } = req.body;

        // Validation
        if (!user_id || !court_name || !court_address || !slot || !booking_date || !price || !payment_method) {
            return res.status(400).json({ message: "Missing required fields" });
        }

        const sql = `
            INSERT INTO bookings 
            (user_id, court_name, court_address, slot, booking_date, price, payment_method)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;

        const [result] = await db.query(sql, [
            user_id,
            court_name,
            court_address,
            slot,
            booking_date,
            price,
            payment_method
        ]);

        res.status(200).json({ 
            message: "Booking created successfully", 
            id: result.insertId 
        });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ 
            message: "Failed to create booking",
            error: err.message 
        });
    }
};

exports.getBookingsByUser = async (req, res) => {
    try {
        const user_id = req.params.user_id;

        const sql = "SELECT * FROM bookings WHERE user_id = ? ORDER BY created_at DESC";

        const [result] = await db.query(sql, [user_id]);

        res.status(200).json(result);
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ 
            message: "Failed to fetch bookings",
            error: err.message 
        });
    }
};
