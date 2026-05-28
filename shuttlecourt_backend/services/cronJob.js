const cron = require('node-cron');
const db = require('../config/database');

// Chạy tự động vào lúc 00:00 mỗi ngày
cron.schedule('0 0 * * *', async () => {
    console.log('🔄 Bắt đầu dọn dẹp hệ thống tự động (Cron Job - Midnight)...');
    try {
        // 1. Xóa các đơn đặt sân (bookings) có ngày đặt nhỏ hơn ngày hiện tại
        const [bookResult] = await db.query("DELETE FROM bookings WHERE booking_date < CURDATE()");
        console.log(`✅ Đã xóa tự động ${bookResult.affectedRows} đơn đặt sân của các ngày trước.`);

        // 2. Xóa các đơn ghép kèo (matchmaking) có ngày nhỏ hơn ngày hiện tại
        const [matchResult] = await db.query("DELETE FROM matchmaking WHERE match_date < CURDATE()");
        console.log(`✅ Đã xóa tự động ${matchResult.affectedRows} đơn ghép kèo của các ngày trước.`);
        
        console.log('✅ Hoàn tất dọn dẹp hệ thống qua ngày mới.');
    } catch (error) {
        console.error('❌ Lỗi khi dọn dẹp hệ thống:', error);
    }
});
