const mysql = require('mysql2');

const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',         // Tài khoản mặc định của XAMPP
  password: '',         // Nếu bạn đặt mật khẩu cho MySQL thì điền vào đây
  database: 'shuttlecourt_db', // Tên database bạn đã tạo
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const promisePool = pool.promise();

let ioInstance = null;

const originalQuery = promisePool.query;
const originalExecute = promisePool.execute;

const handleNotificationInsert = async (sql, params, result) => {
  try {
    const sqlStr = typeof sql === 'string' ? sql.toLowerCase() : '';
    if (sqlStr.includes('insert into notifications') && ioInstance && result && result[0]) {
      const insertId = result[0].insertId;
      const columnsMatch = sql.match(/\(([^)]+)\)/);
      if (columnsMatch && columnsMatch[1]) {
        const columns = columnsMatch[1].split(',').map(c => c.trim().toLowerCase());
        const values = params || [];
        const notification = {};
        columns.forEach((col, idx) => {
          if (idx < values.length) {
            notification[col] = values[idx];
          }
        });
        
        if (notification.user_id) {
          ioInstance.to(`user_${notification.user_id}`).emit('new_notification', {
            id: insertId || Date.now(),
            user_id: Number(notification.user_id),
            sender_id: notification.sender_id ? Number(notification.sender_id) : null,
            title: notification.title || 'Thông báo mới',
            message: notification.message || '',
            type: notification.type || 'general',
            related_id: notification.related_id ? Number(notification.related_id) : null,
            is_read: 0,
            created_at: new Date().toISOString()
          });
          console.log(`📡 Broadcasted notification (id: ${insertId}) to user_${notification.user_id} via hook`);
        }
      }
    }
  } catch (err) {
    console.error('Error in query hook:', err);
  }
};

promisePool.query = async function(...args) {
  const result = await originalQuery.apply(this, args);
  handleNotificationInsert(args[0], args[1], result);
  return result;
};

promisePool.execute = async function(...args) {
  const result = await originalExecute.apply(this, args);
  handleNotificationInsert(args[0], args[1], result);
  return result;
};

promisePool.setIo = (io) => {
  ioInstance = io;
};

module.exports = promisePool;
