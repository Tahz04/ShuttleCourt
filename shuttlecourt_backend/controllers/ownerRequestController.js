const db = require('../config/database');

exports.submitRequest = async (req, res) => {
  try {
    const { userId, courtName, courtAddress, cccdFront, cccdBack } = req.body;
    
    if (!userId || !courtName || !courtAddress || !cccdFront || !cccdBack) {
      return res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin hồ sơ và CCCD.' });
    }

    // Kiểm tra xem đã có chủ sân nào chưa
    const [owners] = await db.query('SELECT id FROM users WHERE role = "owner"');
    if (owners.length > 0) {
      return res.status(403).json({ message: 'Hệ thống đã có chủ sân. Không thể đăng ký thêm.' });
    }

    // Tự động nâng cấp thành chủ sân
    await db.query("UPDATE users SET role = 'owner' WHERE id = ?", [userId]);

    const sql = `
      INSERT INTO owner_requests (user_id, court_name, court_address, cccd_front, cccd_back, status)
      VALUES (?, ?, ?, ?, ?, 'approved')
    `;
    await db.query(sql, [userId, courtName, courtAddress, cccdFront, cccdBack]);
    
    res.status(201).json({ message: 'Chúc mừng! Bạn đã đăng ký thành công và trở thành chủ sân duy nhất.' });
  } catch (err) {
    console.error('Error submitting owner request:', err);
    res.status(500).json({ message: 'Lỗi server khi gửi yêu cầu', error: err.message });
  }
};

exports.getAllRequests = async (req, res) => {
  try {
    const sql = `
      SELECT r.*, u.full_name, u.email 
      FROM owner_requests r
      JOIN users u ON r.user_id = u.id
      WHERE r.status = 'pending'
      ORDER BY r.created_at DESC
    `;
    const [result] = await db.query(sql);
    res.status(200).json(result);
  } catch (err) {
    console.error('Error getting requests:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.approveRequest = async (req, res) => {
  const { requestId } = req.params;
  try {
    // 1. Lấy thông tin request
    const [request] = await db.query('SELECT * FROM owner_requests WHERE id = ?', [requestId]);
    if (request.length === 0) return res.status(404).json({ message: 'Không tìm thấy yêu cầu.' });

    const userId = request[0].user_id;

    // 2. Cập nhật role cho user
    await db.query("UPDATE users SET role = 'owner' WHERE id = ?", [userId]);

    // 3. Đánh dấu request là approved
    await db.query("UPDATE owner_requests SET status = 'approved' WHERE id = ?", [requestId]);

    res.status(200).json({ message: 'Đã phê duyệt yêu cầu thành đối tác.' });
  } catch (err) {
    console.error('Error approving request:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
