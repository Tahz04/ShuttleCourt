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

module.exports = pool.promise();
