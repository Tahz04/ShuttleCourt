const db = require('../config/database');

exports.submitRequest = async (req, res) => {
  try {
    const { userId, fullName, idNumber, cccdFront, cccdBack } = req.body;
    
    if (!userId || !fullName || !idNumber || !cccdFront || !cccdBack) {
      return res.status(400).json({ message: 'Vui lòng cung cấp đầy đủ thông tin hồ sơ và CCCD.' });
    }

    // Kiểm tra xem user này đã gửi yêu cầu chưa
    const [existing] = await db.query('SELECT id FROM owner_requests WHERE user_id = ? AND status = "pending"', [userId]);
    if (existing.length > 0) {
      return res.status(400).json({ message: 'Bạn đã gửi yêu cầu rồi, vui lòng chờ Admin phê duyệt.' });
    }

    const sql = `
      INSERT INTO owner_requests (user_id, full_name, id_number, cccd_front, cccd_back, status)
      VALUES (?, ?, ?, ?, ?, 'pending')
    `;
    await db.query(sql, [userId, fullName, idNumber, cccdFront, cccdBack]);
    
    // Thêm thông báo cho Admin
    const [admins] = await db.query("SELECT id FROM users WHERE role = 'admin'");
    for (const admin of admins) {
      await db.query(
        "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
        [
          admin.id,
          "📝 Hồ sơ chủ sân mới",
          `Người dùng ${fullName} vừa gửi yêu cầu xác minh chủ sân (CCCD: ${idNumber}).`,
          "system"
        ]
      );
    }

    res.status(201).json({ message: 'Đã gửi yêu cầu thành công. Vui lòng chờ Admin phê duyệt!' });
  } catch (err) {
    console.error('Error submitting owner request:', err);
    res.status(500).json({ message: 'Lỗi server khi gửi yêu cầu', error: err.message });
  }
};

exports.getAllRequests = async (req, res) => {
  try {
    const sql = `
      SELECT r.*, u.email 
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

    // 4. Gửi thông báo cho User
    await db.query(
      "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
      [
        userId,
        "🎉 Chúc mừng",
        "Hồ sơ đăng ký Chủ Sân của bạn đã được Admin phê duyệt. Vui lòng đăng nhập lại để trải nghiệm tính năng Quản lý!",
        "system"
      ]
    );

    res.status(200).json({ message: 'Đã phê duyệt yêu cầu thành đối tác.' });
  } catch (err) {
    console.error('Error approving request:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.rejectRequest = async (req, res) => {
  const { requestId } = req.params;
  const { reason } = req.body || {};
  try {
    const [request] = await db.query('SELECT * FROM owner_requests WHERE id = ?', [requestId]);
    if (request.length === 0) return res.status(404).json({ message: 'Không tìm thấy yêu cầu.' });

    const userId = request[0].user_id;
    await db.query("UPDATE owner_requests SET status = 'rejected' WHERE id = ?", [requestId]);

    await db.query(
      "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
      [
        userId,
        "Hồ sơ chủ sân chưa được duyệt",
        reason || "Hồ sơ đăng ký Chủ Sân của bạn chưa được Admin phê duyệt. Vui lòng kiểm tra lại thông tin và gửi lại.",
        "system"
      ]
    );

    res.status(200).json({ message: 'Đã từ chối yêu cầu đăng ký chủ sân.' });
  } catch (err) {
    console.error('Error rejecting request:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
