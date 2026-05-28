const http = require('http');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'shuttlecourt_db'
};

async function createCourtsAndTestRoute() {
    console.log("🚀 Bắt đầu kịch bản tự động tạo sân và test đường đi...");
    try {
        const connection = await mysql.createConnection(dbConfig);
        
        // 1. Tìm user duy77@gmail.com
        const [users] = await connection.execute('SELECT * FROM users WHERE email = ?', ['duy77@gmail.com']);
        if (users.length === 0) {
            console.log("❌ Không tìm thấy user duy77@gmail.com!");
            process.exit(1);
        }
        const user = users[0];
        console.log(`✅ Đã tìm thấy Chủ sân: ${user.full_name} (ID: ${user.id})`);

        // Đảm bảo là owner
        if (user.role !== 'owner') {
            await connection.execute('UPDATE users SET role = "owner" WHERE id = ?', [user.id]);
            console.log("✅ Đã cấp quyền Chủ sân cho user này.");
        }

        // 2. Tạo sân 1: Sân Cầu Lông Hoàn Kiếm (Gần Hồ Gươm)
        const court1 = {
            owner_id: user.id,
            name: 'Sân Cầu Lông Hoàn Kiếm VIP',
            address: 'Đinh Tiên Hoàng, Hàng Trống, Hoàn Kiếm, Hà Nội',
            latitude: 21.028511,
            longitude: 105.854165,
            price_per_hour: 150000,
            description: 'Sân chuẩn thi đấu quốc tế, thảm Yonex, ánh sáng chống chói.',
            main_image: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
            status: 'active'
        };

        // 3. Tạo sân 2: Sân Cầu Lông Cầu Giấy (Gần Đại học Quốc Gia)
        const court2 = {
            owner_id: user.id,
            name: 'Sân Cầu Lông Cầu Giấy Pro',
            address: '144 Xuân Thủy, Dịch Vọng Hậu, Cầu Giấy, Hà Nội',
            latitude: 21.037814,
            longitude: 105.781613,
            price_per_hour: 120000,
            description: 'Sân rộng rãi, có chỗ đỗ ô tô, trần cao 12m.',
            main_image: 'https://images.unsplash.com/photo-1613918431703-9118c7c94ebc?w=800',
            status: 'active'
        };

        // Insert vào DB
        const insertSql = `
            INSERT INTO courts (owner_id, name, address, latitude, longitude, price_per_hour, description, main_image, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        await connection.execute(insertSql, [
            court1.owner_id, court1.name, court1.address, court1.latitude, court1.longitude, court1.price_per_hour, court1.description, court1.main_image, court1.status
        ]);
        console.log(`✅ Đã tạo thành công: ${court1.name}`);

        await connection.execute(insertSql, [
            court2.owner_id, court2.name, court2.address, court2.latitude, court2.longitude, court2.price_per_hour, court2.description, court2.main_image, court2.status
        ]);
        console.log(`✅ Đã tạo thành công: ${court2.name}`);

        await connection.end();

        // 4. Test Route API từ Sân 1 đến Sân 2 (OSRM)
        const start = `${court1.longitude},${court1.latitude}`;
        const end = `${court2.longitude},${court2.latitude}`;
        const osrmUrl = `http://router.project-osrm.org/route/v1/driving/${start};${end}?overview=full&geometries=geojson`;

        console.log(`\n🚗 Đang tính toán đường đi (OSRM) từ Hoàn Kiếm đến Cầu Giấy...`);
        const req = http.get(osrmUrl, (res) => {
            let data = '';
            res.on('data', chunk => { data += chunk; });
            res.on('end', () => {
                const response = JSON.parse(data);
                if (response.code === 'Ok') {
                    const distanceKm = (response.routes[0].distance / 1000).toFixed(2);
                    const durationMin = Math.ceil(response.routes[0].duration / 60);
                    const coordinates = response.routes[0].geometry.coordinates;
                    
                    console.log(`✅ Kết quả Chỉ Đường:`);
                    console.log(`   - Khoảng cách: ${distanceKm} km`);
                    console.log(`   - Thời gian lái xe: ~${durationMin} phút`);
                    console.log(`   - Số lượng điểm uốn cong (Waypoints) trên ngõ ngách: ${coordinates.length} điểm!`);
                    console.log(`\n🎉 Thuật toán định tuyến hoạt động hoàn hảo!`);
                } else {
                    console.log(`❌ Lỗi API OSRM:`, response);
                }
            });
        });

        req.on('error', (e) => {
            console.error(`❌ Lỗi kết nối OSRM: ${e.message}`);
        });

    } catch (error) {
        console.error("❌ Lỗi:", error);
    }
}

createCourtsAndTestRoute();
