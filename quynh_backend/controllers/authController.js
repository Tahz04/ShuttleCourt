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
      { 
        id: user[0].id, 
        email: user[0].email, 
        fullName: user[0].full_name, 
        phone: user[0].phone,
        role: user[0].role // Thêm role vào token
      },
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
        phone: user[0].phone,
        role: user[0].role // Thêm role vào phản hồi
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.upgradeToOwner = async (req, res) => {
  const { userId } = req.body;
  if (!userId) {
    return res.status(400).json({ message: 'Thiếu ID người dùng.' });
  }

  try {
    // Kiểm tra xem đã có chủ sân nào chưa
    const [owners] = await db.query('SELECT id FROM users WHERE role = "owner"');
    if (owners.length > 0) {
      return res.status(403).json({ message: 'Hệ thống đã có chủ sân duy nhất. Không thể nâng cấp thêm.' });
    }

    const [result] = await db.query(
      'UPDATE users SET role = "owner" WHERE id = ?',
      [userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng.' });
    }

    res.json({ message: 'Bạn đã trở thành chủ sân duy nhất của hệ thống!' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server khi nâng cấp', error: err.message });
  }
};

exports.getOwners = async (req, res) => {
  console.log('--- Đang lấy danh sách chủ sân ---');
  try {
    const sql = `
      SELECT u.id, u.full_name as fullName, u.email, u.phone,
             GROUP_CONCAT(c.name SEPARATOR ', ') as courts
      FROM users u
      LEFT JOIN courts c ON u.id = c.owner_id
      WHERE u.role = 'owner'
      GROUP BY u.id
    `;
    const [result] = await db.query(sql);
    res.json(result);
  } catch (err) {
    console.error('Error fetching owners:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};
