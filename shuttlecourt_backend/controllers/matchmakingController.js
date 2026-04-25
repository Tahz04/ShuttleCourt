const db = require('../config/database');

exports.createMatch = async (req, res) => {
  try {
    const { hostId, courtName, level, matchDate, startTime, capacity, price, description } = req.body;
    
    if (!hostId || !courtName || !level || !matchDate || !startTime || !capacity || !price) {
      return res.status(400).json({ message: 'Vui lòng điền đầy đủ thông tin bắt buộc.' });
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
exports.requestJoinMatch = async (req, res) => {
  try {
    const { userId, matchId, hostId, senderName, courtName } = req.body;
    console.log('--- JOIN REQUEST RECEIVED ---');
    console.log('User:', userId, 'Match:', matchId, 'Host:', hostId);

    if (!userId || !matchId || !hostId) {
      console.log('Missing data:', { userId, matchId, hostId });
      return res.status(400).json({ message: 'Thiếu thông tin yêu cầu.' });
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
      // Kiểm tra xem đã đầy chưa
      if (joinedCount >= capacity) {
        return res.status(400).json({ message: 'Kèo đã đầy, không thể chấp nhận thêm.' });
      }

      // 1. Cập nhật joined_count
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
