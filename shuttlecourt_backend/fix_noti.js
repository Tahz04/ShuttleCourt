const fs = require('fs');
let c = fs.readFileSync('controllers/bookingController.js', 'utf8');

const target = `            const icon = status === 'Đã duyệt' ? '✅' : '❌';
            await db.query(
                "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
                [
                    booking.user_id,
                    \`\${icon} Cập nhật lịch sân\`,
                    \`Lịch đặt tại "\${booking.court_name}" của bạn đã được \${status.toLowerCase()}.\`,
                    "booking_status"
                ]
            );
        }`;

const replacement = `            let icon = 'ℹ️';
            let msg = \`Lịch đặt tại "\${booking.court_name}" của bạn đã được cập nhật thành: \${status}.\`;
            
            if (status === 'Đã duyệt') {
                icon = '✅';
                msg = \`Tuyệt vời! Lịch đặt tại "\${booking.court_name}" của bạn đã được CHẤP NHẬN.\`;
            } else if (status === 'Từ chối') {
                icon = '❌';
                msg = \`Rất tiếc! Lịch đặt tại "\${booking.court_name}" của bạn đã bị TỪ CHỐI bởi chủ sân.\`;
            } else if (status === 'Đã hủy') {
                icon = '❌';
                msg = \`Lịch đặt tại "\${booking.court_name}" của bạn đã BỊ HỦY.\`;
            } else if (status === 'Đã hoàn thành') {
                icon = '🏆';
                msg = \`Lịch chơi tại "\${booking.court_name}" đã HOÀN THÀNH. Cảm ơn bạn đã trải nghiệm dịch vụ!\`;
            }

            await db.query(
                "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
                [
                    booking.user_id,
                    \`\${icon} Cập nhật lịch sân\`,
                    msg,
                    "booking_status"
                ]
            );
        }`;

// Using indexOf to find the start and end because spacing might vary slightly.
const startIdx = c.indexOf("const icon = status === 'Đã duyệt' ? '✅' : '❌';");
const endIdx = c.indexOf('        }', startIdx);

if (startIdx !== -1 && endIdx !== -1) {
    c = c.substring(0, startIdx) + replacement + c.substring(endIdx + 9);
    fs.writeFileSync('controllers/bookingController.js', c);
    console.log('Replaced successfully');
} else {
    console.log('Could not find target');
}
