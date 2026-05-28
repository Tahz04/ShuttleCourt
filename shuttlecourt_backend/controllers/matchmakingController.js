const db = require('../config/database');

async function ensureParticipantsTable(connection = db) {
  await connection.query(`
    CREATE TABLE IF NOT EXISTS matchmaking_participants (
      id INT NOT NULL AUTO_INCREMENT,
      match_id INT NOT NULL,
      user_id INT NOT NULL,
      joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY unique_match_user (match_id, user_id),
      CONSTRAINT matchmaking_participants_match_fk FOREIGN KEY (match_id) REFERENCES matchmaking(id) ON DELETE CASCADE,
      CONSTRAINT matchmaking_participants_user_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
  `);
}

exports.createMatch = async (req, res) => {
  try {
    const { hostId, courtName, level, matchDate, startTime, capacity, price, description } = req.body;
    
    if (!hostId || !courtName || !level || !matchDate || !startTime || !capacity || !price) {
      return res.status(400).json({ message: 'Vui lòng điền đầy đủ thông tin bắt buộc.' });
    }

    const [allBookings] = await db.query(
        "SELECT slot FROM bookings WHERE court_name = ? AND booking_date = ? AND status != 'Đã hủy' AND status != 'Từ chối' AND status != 'Đã hoàn thành'",
        [courtName, matchDate]
    );

    const [hrStr, minStr] = startTime.split(':');
    const startMins = parseInt(hrStr, 10) * 60 + parseInt(minStr, 10);
    const endMins = startMins + 60; // Mặc định kèo 1 tiếng

    let isConflict = false;
    for (let b of allBookings) {
        let bStartMins, bEndMins;
        if (b.slot.includes(' - ')) {
            const [s, e] = b.slot.split(' - ');
            bStartMins = parseInt(s.split(':')[0]) * 60 + parseInt(s.split(':')[1]);
            bEndMins = parseInt(e.split(':')[0]) * 60 + parseInt(e.split(':')[1]);
        } else {
            bStartMins = parseInt(b.slot.split(':')[0]) * 60 + parseInt(b.slot.split(':')[1]);
            bEndMins = bStartMins + 60;
        }
        if (startMins < bEndMins && endMins > bStartMins) {
            isConflict = true;
            break;
        }
    }
    if (isConflict) return res.status(409).json({ message: "Khung giờ này đã bị trùng với lịch đặt sân khác." });

    const matchSlot = `${hrStr.padStart(2, '0')}:${minStr.padStart(2, '0')} - ${Math.floor(endMins / 60).toString().padStart(2, '0')}:${(endMins % 60).toString().padStart(2, '0')}`;

    const [courts] = await db.query("SELECT address, owner_id FROM courts WHERE name = ?", [courtName]);
    const courtAddress = courts.length > 0 ? courts[0].address : "Chưa cập nhật";
    let targetOwnerId = courts.length > 0 ? courts[0].owner_id : null;

    await db.query(`INSERT INTO bookings (user_id, court_name, court_address, slot, booking_date, price, payment_method, status) VALUES (?, ?, ?, ?, ?, ?, ?, 'Chờ duyệt')`,
        [hostId, courtName, courtAddress, matchSlot, matchDate, price, 'Ghép kèo']);

    if (req.io) { req.io.to(courtName).emit('booking_updated', { court_name: courtName, booking_date: matchDate, slot: matchSlot, status: 'Chờ duyệt' }); }

    if (!targetOwnerId) {
        const [admins] = await db.query("SELECT id FROM users WHERE role = 'admin' LIMIT 1");
        if (admins.length > 0) targetOwnerId = admins[0].id;
    }
    if (targetOwnerId) {
        await db.query("INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)", [targetOwnerId, "🏸 Đơn đặt sân mới (Ghép kèo)!", `Sân "${courtName}" vừa có Kèo ghép vào ngày ${matchDate} (${startTime}).`, "booking"]);
    }

    const sql = `
      INSERT INTO matchmaking (host_id, court_name, level, match_date, start_time, capacity, price, description)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const [result] = await db.query(sql, [hostId, courtName, level, matchDate, startTime, capacity, price, description || '']);
    
    res.status(201).json({ message: 'Tạo kèo ghép thành công!', matchId: result.insertId });
  } catch (err) {
    console.error('Error creating match:', err);
    res.status(500).json({ message: 'Lỗi server khi tạo kèo', error: err.message });
  }
};

exports.getAllMatches = async (req, res) => {
  try {
    // Join với bảng users để lấy tên host
    const sql = `
      SELECT m.*, u.full_name as host_name 
      FROM matchmaking m
      JOIN users u ON m.host_id = u.id
      ORDER BY m.created_at DESC
    `;
    const [result] = await db.query(sql);
    res.status(200).json(result);
  } catch (err) {
    console.error('Error fetching matches:', err);
    res.status(500).json({ message: 'Lỗi server khi lấy danh sách kèo', error: err.message });
  }
};

// User B yêu cầu tham gia kèo của User A
exports.getUserMatches = async (req, res) => {
  try {
    await ensureParticipantsTable();
    const { userId } = req.params;
    const sql = `
      SELECT DISTINCT m.*, u.full_name as host_name
      FROM matchmaking m
      JOIN users u ON m.host_id = u.id
      LEFT JOIN matchmaking_participants mp ON mp.match_id = m.id
      WHERE m.host_id = ? OR mp.user_id = ?
      ORDER BY m.match_date DESC, m.start_time DESC
    `;
    const [result] = await db.query(sql, [userId, userId]);
    res.status(200).json(result);
  } catch (err) {
    console.error('Error fetching user matches:', err);
    res.status(500).json({ message: 'Failed to fetch user matches', error: err.message });
  }
};

exports.getOwnerMatches = async (req, res) => {
  try {
    const { ownerId } = req.params;
    const sql = `
      SELECT DISTINCT m.*, u.full_name as host_name
      FROM matchmaking m
      JOIN users u ON m.host_id = u.id
      JOIN courts c ON c.name = m.court_name
      WHERE c.owner_id = ?
      ORDER BY m.match_date DESC, m.start_time DESC
    `;
    const [result] = await db.query(sql, [ownerId]);
    res.status(200).json(result);
  } catch (err) {
    console.error('Error fetching owner matches:', err);
    res.status(500).json({ message: 'Failed to fetch owner matches', error: err.message });
  }
};

exports.requestJoinMatch = async (req, res) => {
  try {
    const { userId, matchId, hostId, senderName, courtName } = req.body;
    console.log('--- JOIN REQUEST RECEIVED ---');
    console.log('User:', userId, 'Match:', matchId, 'Host:', hostId);

    if (!userId || !matchId || !hostId) {
      console.log('Missing data:', { userId, matchId, hostId });
      return res.status(400).json({ message: 'Thiếu thông tin yêu cầu.' });
    }

    if (String(userId) === String(hostId)) {
      return res.status(400).json({ message: 'Bạn không thể ghép kèo do chính mình tạo.' });
    }

    const [matchInfo] = await db.query('SELECT capacity, joined_count FROM matchmaking WHERE id = ?', [matchId]);
    if (matchInfo.length > 0 && matchInfo[0].joined_count >= matchInfo[0].capacity) {
      return res.status(400).json({ message: 'Kèo này đã chốt sổ, không thể xin ghép thêm.' });
    }

    await ensureParticipantsTable();
    const [alreadyJoined] = await db.query(
      'SELECT id FROM matchmaking_participants WHERE match_id = ? AND user_id = ?',
      [matchId, userId]
    );

    if (alreadyJoined.length > 0) {
      return res.status(400).json({ message: 'Bạn đã là thành viên của kèo này rồi.' });
    }

    // Kiểm tra xem đã gửi yêu cầu chưa (tránh spam)
    const [existing] = await db.query(
      'SELECT id FROM notifications WHERE user_id = ? AND sender_id = ? AND related_id = ? AND type = "match_join_request" AND is_read = 0',
      [hostId, userId, matchId]
    );

    if (existing.length > 0) {
      return res.status(400).json({ message: 'Bạn đã gửi yêu cầu cho kèo này rồi, vui lòng chờ chủ kèo xác nhận.' });
    }

    // Gửi thông báo đến Host (User A)
    const notificationSql = `
      INSERT INTO notifications (user_id, sender_id, title, message, type, related_id)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    
    await db.query(notificationSql, [
      hostId,
      userId,
      'Yêu cầu ghép kèo mới',
      `${senderName} muốn ghép kèo với bạn tại sân ${courtName}.`,
      'match_join_request',
      matchId
    ]);

    console.log('Notification sent successfully to host');
    res.status(200).json({ message: 'Đã gửi yêu cầu ghép kèo. Vui lòng chờ xác nhận.' });
  } catch (err) {
    console.error('Error requesting join:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
// User A phản hồi yêu cầu (Xác nhận/Từ chối)
exports.respondToJoinRequest = async (req, res) => {
  try {
    const { notificationId, requesterId, matchId, action, hostName } = req.body;

    // Xóa thông báo cũ của host sau khi đã phản hồi
    await db.query('DELETE FROM notifications WHERE id = ?', [notificationId]);

    // Lấy thông tin kèo và kiểm tra capacity
    const [matchRows] = await db.query('SELECT court_name, start_time, match_date, capacity, joined_count FROM matchmaking WHERE id = ?', [matchId]);
    
    if (matchRows.length === 0) {
      return res.status(404).json({ message: 'Kèo không tồn tại.' });
    }

    const { court_name: courtName, capacity, joined_count: joinedCount } = matchRows[0];

    // Lấy tên người yêu cầu
    const [requesterRows] = await db.query('SELECT full_name FROM users WHERE id = ?', [requesterId]);
    const requesterName = requesterRows.length > 0 ? requesterRows[0].full_name : 'Người chơi';

    const notifySql = `
      INSERT INTO notifications (user_id, title, message, type, related_id)
      VALUES (?, ?, ?, ?, ?)
    `;

    if (action === 'accept') {
      await ensureParticipantsTable();
      // Kiểm tra xem đã đầy chưa
      if (joinedCount >= capacity) {
        return res.status(400).json({ message: 'Kèo đã đầy, không thể chấp nhận thêm.' });
      }

      // 1. Cập nhật joined_count
      const [participantResult] = await db.query(
        'INSERT IGNORE INTO matchmaking_participants (match_id, user_id) VALUES (?, ?)',
        [matchId, requesterId]
      );
      if (participantResult.affectedRows === 0) {
        return res.status(400).json({ message: 'Người chơi này đã tham gia kèo.' });
      }
      await db.query('UPDATE matchmaking SET joined_count = joined_count + 1 WHERE id = ?', [matchId]);

      // 2. Gửi thông báo cho Người yêu cầu (User B)
      await db.query(notifySql, [
        requesterId,
        '🎉 Ghép kèo thành công!',
        `Chủ kèo ${hostName} đã đồng ý ghép kèo tại ${courtName}. Đợi 2 bạn ở sân nhé! 🏸`,
        'match_join_success',
        matchId
      ]);

      // 3. Gửi thông báo xác nhận cho chính Chủ kèo (User A)
      const [hostData] = await db.query('SELECT host_id FROM matchmaking WHERE id = ?', [matchId]);
      if (hostData.length > 0) {
        await db.query(notifySql, [
          hostData[0].host_id,
          '✅ Đã xác nhận ghép kèo',
          `Bạn đã chấp nhận ${requesterName} vào kèo tại ${courtName}.`,
          'match_join_success',
          matchId
        ]);
      }
      
      return res.status(200).json({ message: 'Đã chấp nhận yêu cầu ghép kèo.' });
    } else {
      // Thông báo từ chối cho người yêu cầu
      await db.query(notifySql, [
        requesterId,
        'Yêu cầu bị từ chối',
        `Chủ kèo ${hostName} rất tiếc không thể ghép kèo cùng bạn lần này tại ${courtName}.`,
        'match_join_rejected',
        matchId
      ]);

      // Thông báo cho host là đã từ chối thành công
      const [hostData] = await db.query('SELECT host_id FROM matchmaking WHERE id = ?', [matchId]);
      if (hostData.length > 0) {
        await db.query(notifySql, [
          hostData[0].host_id,
          '🚫 Đã từ chối yêu cầu',
          `Bạn đã từ chối yêu cầu tham gia của ${requesterName}.`,
          'match_join_rejected',
          matchId
        ]);
      }

      return res.status(200).json({ message: 'Đã từ chối yêu cầu.' });
    }
  } catch (err) {
    console.error('Error responding to request:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.leaveMatch = async (req, res) => {
  try {
    const { matchId, userId } = req.body;
    const [participant] = await db.query('SELECT * FROM matchmaking_participants WHERE match_id = ? AND user_id = ?', [matchId, userId]);
    
    if (participant.length === 0) {
      return res.status(400).json({ message: 'Bạn không nằm trong kèo này.' });
    }

    await db.query('DELETE FROM matchmaking_participants WHERE match_id = ? AND user_id = ?', [matchId, userId]);
    await db.query('UPDATE matchmaking SET joined_count = GREATEST(1, joined_count - 1) WHERE id = ?', [matchId]);

    const [match] = await db.query('SELECT host_id, court_name FROM matchmaking WHERE id = ?', [matchId]);
    const [user] = await db.query('SELECT full_name FROM users WHERE id = ?', [userId]);

    if (match.length > 0 && user.length > 0) {
      await db.query(
        'INSERT INTO notifications (user_id, sender_id, title, message, type, related_id) VALUES (?, ?, ?, ?, ?, ?)',
        [
          match[0].host_id,
          userId,
          'Thành viên rời kèo',
          `User ${user[0].full_name} đã rời khỏi kèo tại ${match[0].court_name}.`,
          'general',
          matchId
        ]
      );
    }
    
    res.status(200).json({ message: 'Rời kèo thành công.' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.getMatchParticipants = async (req, res) => {
  try {
    const { matchId } = req.params;
    const sql = `
      SELECT u.id, u.full_name, u.email, mp.joined_at, mp.reported 
      FROM matchmaking_participants mp
      JOIN users u ON mp.user_id = u.id
      WHERE mp.match_id = ?
      ORDER BY mp.joined_at ASC
    `;
    const [result] = await db.query(sql, [matchId]);
    res.status(200).json(result);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.reportNoShow = async (req, res) => {
  try {
    const { matchId } = req.params;
    const { participantId, hostId } = req.body;

    const [matchRows] = await db.query('SELECT host_id, court_name FROM matchmaking WHERE id = ?', [matchId]);
    if (matchRows.length === 0 || matchRows[0].host_id !== hostId) {
      return res.status(403).json({ message: 'Không có quyền thực hiện.' });
    }

    const [participantRows] = await db.query('SELECT reported FROM matchmaking_participants WHERE match_id = ? AND user_id = ?', [matchId, participantId]);
    if (participantRows.length === 0) return res.status(404).json({ message: 'Người chơi không có trong kèo này.' });
    if (participantRows[0].reported) return res.status(400).json({ message: 'Bạn đã báo cáo người này rồi.' });

    await db.query('UPDATE matchmaking_participants SET reported = TRUE WHERE match_id = ? AND user_id = ?', [matchId, participantId]);
    await db.query('UPDATE users SET reputation_score = reputation_score - 10 WHERE id = ?', [participantId]);
    
    const [userRows] = await db.query('SELECT reputation_score, full_name FROM users WHERE id = ?', [participantId]);
    const newScore = userRows[0].reputation_score;

    if (newScore < 70) {
      await db.query("UPDATE users SET status = 'locked' WHERE id = ?", [participantId]);
      await db.query(
        "INSERT INTO notifications (user_id, sender_id, title, message, type) VALUES (?, ?, ?, ?, ?)",
        [participantId, null, "Tài khoản bị khóa", `Tài khoản của bạn đã bị khóa do điểm uy tín giảm xuống dưới 70đ (Hiện tại: ${newScore}đ). Vui lòng liên hệ Admin.`, "system"]
      );
    } else {
      await db.query(
        "INSERT INTO notifications (user_id, sender_id, title, message, type) VALUES (?, ?, ?, ?, ?)",
        [participantId, hostId, "Cảnh báo vắng mặt", `Chủ kèo ${matchRows[0].court_name} đã báo cáo bạn không đến tham gia. Điểm uy tín của bạn bị trừ 10đ (Hiện tại: ${newScore}đ).`, "warning"]
      );
    }

    res.status(200).json({ message: 'Đã báo cáo thành công.' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
