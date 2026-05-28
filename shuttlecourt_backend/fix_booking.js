const fs = require('fs');
let c = fs.readFileSync('controllers/bookingController.js', 'utf8');

const p1 = c.indexOf('// Kiểm tra trùng lịch (Concurrency Check)');
const p2 = c.indexOf('const sql = `');

if (p1 > -1 && p2 > -1) {
    const replacement = `        // Kiểm tra trùng lịch (Concurrency Check - Overlap logic)
        const [existing] = await db.query(
            "SELECT slot FROM bookings WHERE court_name = ? AND booking_date = ? AND status != 'Đã hủy' AND status != 'Từ chối' AND status != 'Đã hoàn thành'",
            [court_name, booking_date]
        );

        let isConflict = false;
        const reqStartMins = parseInt(slot.split(' - ')[0].split(':')[0]) * 60 + parseInt(slot.split(' - ')[0].split(':')[1]);
        const reqEndMins = parseInt(slot.split(' - ')[1].split(':')[0]) * 60 + parseInt(slot.split(' - ')[1].split(':')[1]);

        for (let b of existing) {
            let bStartMins, bEndMins;
            if (b.slot.includes(' - ')) {
                const [s, e] = b.slot.split(' - ');
                bStartMins = parseInt(s.split(':')[0]) * 60 + parseInt(s.split(':')[1]);
                bEndMins = parseInt(e.split(':')[0]) * 60 + parseInt(e.split(':')[1]);
            } else {
                bStartMins = parseInt(b.slot.split(':')[0]) * 60 + parseInt(b.slot.split(':')[1]);
                bEndMins = bStartMins + 60;
            }
            if (reqStartMins < bEndMins && reqEndMins > bStartMins) {
                isConflict = true;
                break;
            }
        }

        if (isConflict) {
            return res.status(409).json({ message: "Rất tiếc! Sân này vừa có người đặt trong khung giờ này." });
        }

        `;
    
    c = c.substring(0, p1) + replacement + c.substring(p2);
    fs.writeFileSync('controllers/bookingController.js', c);
    console.log('Replaced successfully');
} else {
    console.log('Could not find markers', {p1, p2});
}
