const db = require('../config/database');

exports.getDashboardStats = async (req, res) => {
  try {
    const [[userCount]] = await db.query("SELECT COUNT(*) as count FROM users");
    const [[courtCount]] = await db.query("SELECT COUNT(*) as count FROM courts");
    
    // Tổng doanh thu từ Shop
    const [[shopRevenue]] = await db.query("SELECT SUM(total_price) as total FROM product_orders WHERE status = 'Đã giao' OR status = 'Đã duyệt'");
    
    // Tổng doanh thu từ Booking
    const [[bookingRevenue]] = await db.query("SELECT SUM(price) as total FROM bookings WHERE status = 'approved' OR status = 'paid'");

    res.json({
      totalUsers: userCount.count,
      totalCourts: courtCount.count,
      totalShopRevenue: shopRevenue.total || 0,
      totalBookingRevenue: bookingRevenue.total || 0,
    });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.getAllUsers = async (req, res) => {
  try {
    const [users] = await db.query("SELECT id, full_name, email, phone, role, status, created_at FROM users ORDER BY created_at DESC");
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.toggleUserLock = async (req, res) => {
  const { id } = req.params;
  try {
    const [[user]] = await db.query("SELECT status FROM users WHERE id = ?", [id]);
    if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng' });

    const newStatus = user.status === 'locked' ? 'active' : 'locked';
    await db.query("UPDATE users SET status = ? WHERE id = ?", [newStatus, id]);

    res.json({ message: `Đã ${newStatus === 'locked' ? 'khóa' : 'mở khóa'} tài khoản thành công.`, newStatus });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
