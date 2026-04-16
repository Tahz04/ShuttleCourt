const db = require('./config/database');

async function updateNotificationsTable() {
  console.log('--- ĐANG CẬP NHẬT BẢNG THÔNG BÁO ---');
  try {
    // Thêm các cột sender_id và related_id nếu chưa có
    const [columns] = await db.query('SHOW COLUMNS FROM notifications');
    const columnNames = columns.map(c => c.Field);

    if (!columnNames.includes('sender_id')) {
      await db.query('ALTER TABLE notifications ADD COLUMN sender_id INT DEFAULT NULL');
      console.log('✅ Đã thêm cột sender_id');
    }

    if (!columnNames.includes('related_id')) {
      await db.query('ALTER TABLE notifications ADD COLUMN related_id INT DEFAULT NULL');
      console.log('✅ Đã thêm cột related_id');
    }

    console.log('✅ Bảng notifications đã sẵn sàng!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
    process.exit(1);
  }
}

updateNotificationsTable();
