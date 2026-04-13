const db = require('../config/database');

exports.getAllCourts = async (req, res) => {
    try {
        const sql = "SELECT * FROM courts ORDER BY name ASC";
        const [result] = await db.query(sql);
        res.status(200).json(result);
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ 
            message: "Failed to fetch courts",
            error: err.message 
        });
    }
};

exports.getCourtById = async (req, res) => {
    try {
        const sql = "SELECT * FROM courts WHERE id = ?";
        const [result] = await db.query(sql, [req.params.id]);
        if (result.length === 0) {
            return res.status(404).json({ message: "Court not found" });
        }
        res.status(200).json(result[0]);
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ 
            message: "Failed to fetch court",
            error: err.message 
        });
    }
};

exports.getCourtsByOwner = async (req, res) => {
    try {
        const { ownerId } = req.params;
        const sql = "SELECT * FROM courts WHERE owner_id = ? ORDER BY created_at DESC";
        const [result] = await db.query(sql, [ownerId]);
        res.status(200).json(result);
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ 
            message: "Failed to fetch owner's courts",
            error: err.message 
        });
    }
};

exports.addCourt = async (req, res) => {
    try {
        const { ownerId, name, address, latitude, longitude, price, description } = req.body;
        
        // Validation cơ bản
        if (!ownerId || !name || !address || !price) {
            return res.status(400).json({ message: "Vui lòng điền đầy đủ các thông tin bắt buộc" });
        }

        const sql = `
            INSERT INTO courts (owner_id, name, address, latitude, longitude, price_per_hour, description)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;
        
        const [result] = await db.query(sql, [
            ownerId, 
            name, 
            address, 
            latitude || null, 
            longitude || null, 
            price, 
            description || ''
        ]);

        res.status(201).json({ 
            message: "Thêm sân thành công",
            courtId: result.insertId 
        });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ 
            message: "Không thể thêm sân",
            error: err.message 
        });
    }
};
