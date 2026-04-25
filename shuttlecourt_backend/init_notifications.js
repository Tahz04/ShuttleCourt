const db = require('./config/database');

async function createNotificationsTable() {
  console.log('--- ĐANG KHỞI TẠO HỆ THỐNG THÔNG BÁO ---');
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT, -- Người nhận (Owner)
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        is_read TINYINT(1) DEFAULT 0,
        type VARCHAR(50), -- 'order', 'booking', 'match'
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    `);
    console.log('✅ Khởi tạo thành công!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
    process.exit(1);
  }
}

createNotificationsTable();
