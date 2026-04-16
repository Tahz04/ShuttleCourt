const db = require('../config/database');

exports.getNotifications = async (req, res) => {
  const { userId } = req.params;
  try {
    const [rows] = await db.query(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
      [userId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.markAsRead = async (req, res) => {
  const { notificationId } = req.params;
  try {
    await db.query('UPDATE notifications SET is_read = 1 WHERE id = ?', [notificationId]);
    res.json({ message: 'Đã đọc thông báo' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.markAllAsRead = async (req, res) => {
  const { userId } = req.params;
  try {
    await db.query('UPDATE notifications SET is_read = 1 WHERE user_id = ?', [userId]);
    res.json({ message: 'Đã đọc tất cả thông báo' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
