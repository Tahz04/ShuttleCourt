const db = require('../config/database');
const NodeCache = require('node-cache');
const myCache = new NodeCache({ stdTTL: 600 }); // Cache sống trong 10 phút

exports.getAllCourts = async (req, res) => {
    try {
        console.log('📍 GET /api/courts/all - Request received');
        const cachedCourts = myCache.get('all_courts');
        if (cachedCourts) {
            console.log('✅ Serving courts from Cache (Super Fast)');
            return res.status(200).json(cachedCourts);
        }

        const sql = `
            SELECT c.*, u.full_name as owner_name 
            FROM courts c 
            LEFT JOIN users u ON c.owner_id = u.id 
            ORDER BY c.name ASC
        `;
        const [result] = await db.query(sql);
        console.log(`✅ Courts found: ${result.length} records`);
        
        // Lưu vào cache
        myCache.set('all_courts', result);
        
        res.status(200).json(result);
    } catch (err) {
        console.error('❌ Database error:', err);
        res.status(500).json({ message: "Failed to fetch courts", error: err.message });
    }
};

exports.getCourtById = async (req, res) => {
    try {
        const sql = "SELECT * FROM courts WHERE id = ?";
        const [result] = await db.query(sql, [req.params.id]);
        if (result.length === 0) return res.status(404).json({ message: "Court not found" });
        res.status(200).json(result[0]);
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ message: "Failed to fetch court", error: err.message });
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
        res.status(500).json({ message: "Failed to fetch owner's courts", error: err.message });
    }
};

exports.addCourt = async (req, res) => {
    try {
        const { ownerId, name, address, latitude, longitude, price, description, main_image, desc_image1, desc_image2 } = req.body;
        
        if (!ownerId || !name || !address || !price) {
            return res.status(400).json({ message: "Vui lòng điền đầy đủ các thông tin bắt buộc" });
        }

        const sql = `
            INSERT INTO courts (owner_id, name, address, latitude, longitude, price_per_hour, description, main_image, desc_image1, desc_image2, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')
        `;
        
        const [result] = await db.query(sql, [
            ownerId, name, address, latitude || null, longitude || null, price, description || '', 
            main_image || null, desc_image1 || null, desc_image2 || null
        ]);

        // Clear cache vì danh sách sân đã thay đổi
        myCache.del('all_courts');

        res.status(201).json({ message: "Thêm sân thành công", courtId: result.insertId });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ message: "Không thể thêm sân", error: err.message });
    }
};

exports.updateCourt = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, address, latitude, longitude, price, description, main_image, desc_image1, desc_image2, status, isAdmin } = req.body;
        
        const [courtData] = await db.query("SELECT owner_id, name FROM courts WHERE id = ?", [id]);
        
        const sql = `
            UPDATE courts 
            SET name=?, address=?, latitude=?, longitude=?, price_per_hour=?, description=?, 
                main_image=?, desc_image1=?, desc_image2=?, status=?
            WHERE id=?
        `;
        
        await db.query(sql, [
            name, address, latitude, longitude, price, description, 
            main_image, desc_image1, desc_image2, status, id
        ]);

        if (isAdmin && courtData.length > 0) {
            await db.query(
                "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
                [
                    courtData[0].owner_id,
                    "Cập nhật từ Admin",
                    `Admin vừa cập nhật thông tin sân "${courtData[0].name}" của bạn.`,
                    "general"
                ]
            );
        }

        // Clear cache vì thông tin sân đã thay đổi
        myCache.del('all_courts');

        res.status(200).json({ message: "Cập nhật sân thành công" });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ message: "Không thể cập nhật sân", error: err.message });
    }
};

exports.deleteCourt = async (req, res) => {
    try {
        const { id } = req.params;
        const { isAdmin } = req.query;

        const [courtData] = await db.query("SELECT owner_id, name FROM courts WHERE id = ?", [id]);

        await db.query("DELETE FROM courts WHERE id = ?", [id]);

        if (isAdmin === 'true' && courtData.length > 0) {
            await db.query(
                "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
                [
                    courtData[0].owner_id,
                    "Sân đã bị xóa",
                    `Admin vừa xóa sân "${courtData[0].name}" của bạn do vi phạm hoặc theo yêu cầu.`,
                    "general"
                ]
            );
        }

        // Clear cache vì danh sách sân đã thay đổi
        myCache.del('all_courts');

        res.status(200).json({ message: "Xóa sân thành công" });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ message: "Không thể xóa sân", error: err.message });
    }
};

exports.toggleMaintenance = async (req, res) => {
    try {
        const { id } = req.params;
        const { isMaintenance, isAdmin } = req.body;
        const status = isMaintenance ? 'maintenance' : 'active';
        
        const [courtData] = await db.query("SELECT owner_id, name FROM courts WHERE id = ?", [id]);

        await db.query("UPDATE courts SET status = ? WHERE id = ?", [status, id]);

        if (isAdmin && courtData.length > 0) {
            const statusMsg = isMaintenance ? "được chuyển sang trạng thái BẢO TRÌ" : "được mở lại HOẠT ĐỘNG";
            await db.query(
                "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
                [
                    courtData[0].owner_id,
                    "Trạng thái sân thay đổi",
                    `Sân "${courtData[0].name}" của bạn vừa ${statusMsg} bởi Admin.`,
                    "general"
                ]
            );
        }

        res.status(200).json({ message: "Cập nhật trạng thái bảo trì thành công", status });
    } catch (err) {
        console.error('Database error:', err);
        res.status(500).json({ message: "Không thể cập nhật trạng thái", error: err.message });
    }
};
