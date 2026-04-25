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

        // THÔNG BÁO CHO CHỦ SÂN
        const [owners] = await db.query("SELECT id FROM users WHERE role = 'owner'");
        for (const owner of owners) {
          await db.query(
            "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
            [
              owner.id,
              "🏸 Lịch đặt sân mới!",
              `Sân "${court_name}" được đặt vào ngày ${booking_date} (Khung giờ: ${slot}).`,
              "booking"
            ]
          );
        }

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

exports.getAllBookings = async (req, res) => {
    try {
        const sql = `
            SELECT b.*, u.full_name as user_name 
            FROM bookings b
            JOIN users u ON b.user_id = u.id
            ORDER BY b.created_at DESC
        `;
        const [result] = await db.query(sql);
        res.status(200).json(result);
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ message: "Failed to fetch all bookings", error: err.message });
    }
};

exports.updateBookingStatus = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    try {
        // 1. Cập nhật trạng thái
        await db.query('UPDATE bookings SET status = ? WHERE id = ?', [status, id]);

        // 2. Lấy user_id và thông tin sân để gửi thông báo cho khách
        const [[booking]] = await db.query('SELECT user_id, court_name FROM bookings WHERE id = ?', [id]);
        
        if (booking) {
            const icon = status === 'Đã duyệt' ? '✅' : '❌';
            await db.query(
                "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
                [
                    booking.user_id,
                    `${icon} Cập nhật lịch sân`,
                    `Lịch đặt tại "${booking.court_name}" của bạn đã được ${status.toLowerCase()}.`,
                    "booking_status"
                ]
            );
        }

        res.status(200).json({ message: 'Cập nhật trạng thái thành công' });
    } catch (err) {
        res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
};