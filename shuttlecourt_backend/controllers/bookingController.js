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

                // Kiểm tra trùng lịch (Concurrency Check - Overlap logic)
        const [existing] = await db.query(
            "SELECT slot FROM bookings WHERE court_name = ? AND booking_date = ? AND status != 'Đã hủy' AND status != 'Từ chối' AND status != 'Đã hoàn thành'",
            [court_name, booking_date]
        );

        let isConflict = false;
        const reqStartMins = parseInt(slot.split(' - ')[0].split(':')[0]) * 60 + parseInt(slot.split(' - ')[0].split(':')[1]);
        const reqEndMins = parseInt(slot.split(' - ')[1].split(':')[0]) * 60 + parseInt(slot.split(' - ')[1].split(':')[1]);

        for (let b of existing) {
            let bStartMins, bEndMins;
            if (b.slot.includes(' - ')) {
                const [s, e] = b.slot.split(' - ');
                bStartMins = parseInt(s.split(':')[0]) * 60 + parseInt(s.split(':')[1]);
                bEndMins = parseInt(e.split(':')[0]) * 60 + parseInt(e.split(':')[1]);
            } else {
                bStartMins = parseInt(b.slot.split(':')[0]) * 60 + parseInt(b.slot.split(':')[1]);
                bEndMins = bStartMins + 60;
            }
            if (reqStartMins < bEndMins && reqEndMins > bStartMins) {
                isConflict = true;
                break;
            }
        }

        if (isConflict) {
            return res.status(409).json({ message: "Rất tiếc! Sân này vừa có người đặt trong khung giờ này." });
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

        // Lấy owner thực sự của sân (người đã tạo sân)
        const [courts] = await db.query("SELECT owner_id FROM courts WHERE name = ?", [court_name]);
        let targetOwnerId = null;
        if (courts.length > 0) targetOwnerId = courts[0].owner_id;

        const notificationReceivers = new Set();
        if (targetOwnerId) {
            notificationReceivers.add(targetOwnerId);
        } else {
            // Nếu sân cũ không có owner_id, gửi tạm cho admin đầu tiên
            const [admins] = await db.query("SELECT id FROM users WHERE role = 'admin' LIMIT 1");
            if (admins.length > 0) notificationReceivers.add(admins[0].id);
        }

        for (const uid of notificationReceivers) {
          await db.query(
            "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
            [
              uid,
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

exports.getBookingsByOwner = async (req, res) => {
    try {
        const { ownerId } = req.params;
        const sql = `
            SELECT b.*, u.full_name as user_name
            FROM bookings b
            JOIN users u ON b.user_id = u.id
            JOIN courts c ON b.court_name = c.name
            WHERE c.owner_id = ?
            ORDER BY b.created_at DESC
        `;
        const [result] = await db.query(sql, [ownerId]);
        res.status(200).json(result);
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ message: "Failed to fetch owner's bookings", error: err.message });
    }
};

exports.updateBookingStatus = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    try {
        // 1. Cập nhật trạng thái
        await db.query('UPDATE bookings SET status = ? WHERE id = ?', [status, id]);

        // 2. Lấy user_id và thông tin sân để gửi thông báo cho khách
        const [[booking]] = await db.query('SELECT user_id, court_name, booking_date, slot FROM bookings WHERE id = ?', [id]);
        
        if (booking) {
            if (req.io) { req.io.to(booking.court_name).emit('booking_updated', { court_name: booking.court_name, booking_date: booking.booking_date, slot: booking.slot, status }); }
            
            if (status === 'Từ chối' || status === 'Đã hủy' || status === 'Đã hoàn thành') {
                await db.query(
                    "DELETE FROM matchmaking WHERE court_name = ? AND match_date = ? AND start_time = ?",
                    [booking.court_name, booking.booking_date, booking.slot]
                );
            }

                        let icon = 'ℹ️';
            let msg = `Lịch đặt tại "${booking.court_name}" của bạn đã được cập nhật thành: ${status}.`;
            
            if (status === 'Đã duyệt') {
                icon = '✅';
                msg = `Tuyệt vời! Lịch đặt tại "${booking.court_name}" của bạn đã được CHẤP NHẬN.`;
            } else if (status === 'Từ chối') {
                icon = '❌';
                msg = `Rất tiếc! Lịch đặt tại "${booking.court_name}" của bạn đã bị TỪ CHỐI bởi chủ sân.`;
            } else if (status === 'Đã hủy') {
                icon = '❌';
                msg = `Lịch đặt tại "${booking.court_name}" của bạn đã BỊ HỦY.`;
            } else if (status === 'Đã hoàn thành') {
                icon = '🏆';
                msg = `Lịch chơi tại "${booking.court_name}" đã HOÀN THÀNH. Cảm ơn bạn đã trải nghiệm dịch vụ!`;
            }

            await db.query(
                "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
                [
                    booking.user_id,
                    `${icon} Cập nhật lịch sân`,
                    msg,
                    "booking_status"
                ]
            );
        }

        res.status(200).json({ message: 'Cập nhật trạng thái thành công' });
    } catch (err) {
        res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
};

exports.getBookedSlots = async (req, res) => {
    try {
        const { court_name, booking_date } = req.query;
        if (!court_name || !booking_date) {
            return res.status(400).json({ message: "Missing required query parameters" });
        }

        const sql = `
            SELECT slot FROM bookings 
            WHERE court_name = ? AND booking_date = ? 
            AND status != 'Đã hủy' AND status != 'Từ chối' AND status != 'Đã hoàn thành'
        `;
        const [rows] = await db.query(sql, [court_name, booking_date]);
        
        const bookedSlots = rows.map(r => r.slot);
        res.status(200).json(bookedSlots);
    } catch (err) {
        res.status(500).json({ message: 'Lỗi server', error: err.message });
    }
};

exports.cancelBooking = async (req, res) => {
    try {
        const { id } = req.params;
        const { user_id } = req.body;

        const [bookings] = await db.query('SELECT user_id, court_name, booking_date, slot FROM bookings WHERE id = ?', [id]);
        if (bookings.length === 0) return res.status(404).json({ message: "Không tìm thấy booking" });
        
        const booking = bookings[0];
        if (booking.user_id !== user_id) return res.status(403).json({ message: "Không có quyền hủy" });

        await db.query("UPDATE bookings SET status = 'Đã hủy' WHERE id = ?", [id]);
        
        await db.query(
            "DELETE FROM matchmaking WHERE court_name = ? AND match_date = ? AND start_time = ?",
            [booking.court_name, booking.booking_date, booking.slot]
        );
        
        if (req.io) {
            req.io.to(booking.court_name).emit('booking_updated', {
                court_name: booking.court_name,
                booking_date: booking.booking_date,
                slot: booking.slot,
                status: 'Đã hủy'
            });
        }
        
        const [courts] = await db.query("SELECT owner_id FROM courts WHERE name = ?", [booking.court_name]);
        if (courts.length > 0 && courts[0].owner_id) {
            await db.query(
                "INSERT INTO notifications (user_id, sender_id, title, message, type, related_id) VALUES (?, ?, ?, ?, ?, ?)",
                [courts[0].owner_id, user_id, "Lịch đặt bị hủy", `Khách hàng đã hủy lịch đặt sân ${booking.court_name} lúc ${booking.slot}.`, "booking", id]
            );
        }

        res.status(200).json({ message: "Đã hủy lịch đặt sân." });
    } catch (err) {
        res.status(500).json({ message: "Lỗi server", error: err.message });
    }
};
