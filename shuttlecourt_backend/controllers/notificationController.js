const db = require('../config/database');

exports.getNotifications = async (req, res) => {
  const { userId } = req.params;
  try {
    const [rows] = await db.query(
      `SELECT n.*, u.full_name as sender_name
       FROM notifications n
       LEFT JOIN users u ON n.sender_id = u.id
       WHERE n.user_id = ?
       ORDER BY n.created_at DESC LIMIT 50`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.createNotification = async (req, res) => {
  const { userId, title, message, type, senderId, relatedId } = req.body;
  try {
    await db.query(
      'INSERT INTO notifications (user_id, sender_id, title, message, type, related_id) VALUES (?, ?, ?, ?, ?, ?)',
      [userId, senderId || null, title, message, type || 'general', relatedId || null]
    );
    res.status(201).json({ message: 'Đã tạo thông báo' });
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
