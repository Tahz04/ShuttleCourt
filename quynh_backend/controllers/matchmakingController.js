const db = require('../config/database');

exports.createMatch = async (req, res) => {
  try {
    const { hostId, courtName, level, matchDate, startTime, capacity, price, description } = req.body;
    
    if (!hostId || !courtName || !level || !matchDate || !startTime || !capacity || !price) {
      return res.status(400).json({ message: 'Vui lòng điền đầy đủ thông tin bắt buộc.' });
    }

    const sql = `
      INSERT INTO matchmaking (host_id, court_name, level, match_date, start_time, capacity, price, description)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const [result] = await db.query(sql, [hostId, courtName, level, matchDate, startTime, capacity, price, description || '']);
    
    res.status(201).json({ message: 'Tạo kèo ghép thành công!', matchId: result.insertId });
  } catch (err) {
    console.error('Error creating match:', err);
    res.status(500).json({ message: 'Lỗi server khi tạo kèo', error: err.message });
  }
};

exports.getAllMatches = async (req, res) => {
  try {
    // Join với bảng users để lấy tên host
    const sql = `
      SELECT m.*, u.full_name as host_name 
      FROM matchmaking m
      JOIN users u ON m.host_id = u.id
      ORDER BY m.created_at DESC
    `;
    const [result] = await db.query(sql);
    res.status(200).json(result);
  } catch (err) {
    console.error('Error fetching matches:', err);
    res.status(500).json({ message: 'Lỗi server khi lấy danh sách kèo', error: err.message });
  }
};
