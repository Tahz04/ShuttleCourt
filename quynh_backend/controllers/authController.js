const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

exports.register = async (req, res) => {
  const { fullName, email, phone, password } = req.body;
  if (!fullName || !email || !phone || !password) {
    return res.status(400).json({ message: 'Vui lòng nhập đầy đủ thông tin.' });
  }
  try {
    // Kiểm tra email đã tồn tại chưa
    const [user] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (user.length > 0) {
      return res.status(400).json({ message: 'Email đã tồn tại.' });
    }
    // Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, 10);
    // Lưu vào database
    await db.query(
      'INSERT INTO users (full_name, email, phone, password) VALUES (?, ?, ?, ?)',
      [fullName, email, phone, hashedPassword]
    );
    res.status(201).json({ message: 'Đăng ký thành công!' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu.' });
  }
  try {
    const [user] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (user.length === 0) {
      return res.status(400).json({ message: 'Email không tồn tại.' });
    }
    const valid = await bcrypt.compare(password, user[0].password);
    if (!valid) {
      return res.status(400).json({ message: 'Mật khẩu không đúng.' });
    }
    // Tạo token (JWT)
    const token = jwt.sign(
      { id: user[0].id, email: user[0].email, fullName: user[0].full_name, phone: user[0].phone },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );
    res.json({
      message: 'Đăng nhập thành công!',
      token,
      user: {
        id: user[0].id,
        email: user[0].email,
        fullName: user[0].full_name,
        phone: user[0].phone
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
