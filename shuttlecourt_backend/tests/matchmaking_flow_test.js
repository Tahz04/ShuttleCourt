/**
 * ============================================================
 * BACKEND TEST: Matchmaking & Notification Flow Tests
 * Tương ứng: tests_shuttlecourt/02_Flow_Integration_Test.md
 *   - Luồng 4: Ghép kèo (Accept)
 *   - Luồng 5: Ghép kèo (Reject)
 *   - Luồng 7: Duyệt booking (Owner Approval)
 * 
 * CÁCH CHẠY:
 *   1. Server phải đang chạy (node server.js)
 *   2. MySQL (XAMPP) phải bật, có user id=1
 *   3. Chạy: node tests/matchmaking_flow_test.js
 * ============================================================
 */

const http = require('http');
const db = require('../config/database');

let passCount = 0;
let failCount = 0;
let totalTests = 0;

// ── HELPERS ──────────────────────────────────────────────────

function post(path, data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);
    const options = {
      hostname: 'localhost', port: 3000, path, method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };
    const req = http.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => responseBody += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(responseBody) }); }
        catch { resolve({ status: res.statusCode, body: responseBody }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function get(path) {
  return new Promise((resolve, reject) => {
    http.get(`http://localhost:3000${path}`, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(body) }); }
        catch { resolve({ status: res.statusCode, body }); }
      });
    }).on('error', reject);
  });
}

function put(path, data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);
    const options = {
      hostname: 'localhost', port: 3000, path, method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };
    const req = http.request(options, (res) => {
      let rb = '';
      res.on('data', (chunk) => rb += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(rb) }); }
        catch { resolve({ status: res.statusCode, body: rb }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function assert(testId, testName, condition, detail = '') {
  totalTests++;
  if (condition) {
    passCount++;
    console.log(`  ✅ ${testId}: ${testName}`);
  } else {
    failCount++;
    console.log(`  ❌ ${testId}: ${testName} ${detail ? '→ ' + detail : ''}`);
  }
}

// ── FLOW 1: TẠO KÈO GHÉP (Matchmaking Create) ──────────────

async function testMatchmakingCreate() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  FLOW 1: TẠO KÈO GHÉP (Create Match)        ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Bước 1: Tạo kèo thành công
  console.log('\n  📌 Bước 1: User A tạo kèo ghép');
  const matchData = {
    hostId: 1,
    courtName: 'Duy Hung Badminton Center',
    level: 'Trung bình',
    matchDate: '2026-06-20',
    startTime: '18:00',
    capacity: 4,
    price: 50000,
    description: 'Tìm 3 bạn ghép kèo đánh cầu lông'
  };

  const createRes = await post('/api/matchmaking/create', matchData);
  assert('MM-CR-01', 'Tạo kèo thành công (201)', createRes.status === 201);
  assert('MM-CR-02', 'Trả về matchId', createRes.body.matchId !== undefined);

  const matchId = createRes.body.matchId;
  console.log(`  🎯 Match ID: ${matchId}`);

  // Bước 2: Tạo kèo thiếu thông tin
  console.log('\n  📌 Bước 2: Tạo kèo thiếu thông tin');
  const r2 = await post('/api/matchmaking/create', { hostId: 1 });
  assert('MM-CR-03', 'Tạo kèo thiếu thông tin → 400', r2.status === 400);

  // Bước 3: Lấy danh sách kèo
  console.log('\n  📌 Bước 3: Lấy danh sách kèo');
  const listRes = await get('/api/matchmaking/all');
  assert('MM-CR-04', 'GET /matchmaking/all → 200', listRes.status === 200);
  assert('MM-CR-05', 'Trả về mảng matches', Array.isArray(listRes.body));

  if (Array.isArray(listRes.body) && listRes.body.length > 0) {
    const match = listRes.body.find(m => m.id === matchId);
    assert('MM-CR-06', 'Kèo vừa tạo có trong danh sách', match !== undefined);
    if (match) {
      assert('MM-CR-07', 'Kèo có host_name (JOIN users)', match.host_name !== undefined);
    }
  }

  return matchId;
}

// ── FLOW 2: GỬI YÊU CẦU GHÉP KÈO (Join Request) ───────────

async function testJoinRequest(matchId) {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  FLOW 2: GỬI YÊU CẦU GHÉP KÈO (Join)       ║');
  console.log('╚══════════════════════════════════════════════╝');

  if (!matchId) {
    console.log('  ⚠️ Không có matchId, bỏ qua');
    return;
  }

  // Bước 1: Gửi yêu cầu tham gia thiếu thông tin
  console.log('\n  📌 Bước 1: Join request thiếu thông tin');
  const r1 = await post('/api/matchmaking/join', {});
  assert('MM-JN-01', 'Join thiếu thông tin → 400', r1.status === 400);
  assert('MM-JN-02', 'Trả về message lỗi', r1.body.message !== undefined);

  // Bước 2: Gửi yêu cầu hợp lệ (User B = id 2 muốn join kèo của User A = id 1)
  // Lưu ý: Cần có user id=2 trong DB, nếu không sẽ test edge case
  console.log('\n  📌 Bước 2: User B gửi yêu cầu ghép kèo');
  const joinRes = await post('/api/matchmaking/join', {
    userId: 2,
    matchId: matchId,
    hostId: 1,
    senderName: 'User B Test',
    courtName: 'Duy Hung Badminton Center'
  });
  
  // Có thể 200 (thành công) hoặc 400 (đã gửi rồi)
  assert('MM-JN-03', 'Join request trả về 200 hoặc 400',
    joinRes.status === 200 || joinRes.status === 400,
    `Status: ${joinRes.status}`
  );

  // Bước 3: Gửi lại lần 2 → chống spam
  if (joinRes.status === 200) {
    console.log('\n  📌 Bước 3: Gửi join request lần 2 (spam check)');
    const spamRes = await post('/api/matchmaking/join', {
      userId: 2,
      matchId: matchId,
      hostId: 1,
      senderName: 'User B Test',
      courtName: 'Duy Hung Badminton Center'
    });
    assert('MM-JN-04', 'Chống spam: Gửi lại lần 2 → 400',
      spamRes.status === 400,
      `Status: ${spamRes.status}`
    );
    assert('MM-JN-05', 'Message chống spam chứa "đã gửi yêu cầu"',
      typeof spamRes.body.message === 'string' && spamRes.body.message.includes('đã gửi'),
      `Message: ${spamRes.body.message}`
    );
  }
}

// ── FLOW 3: PHẢN HỒI YÊU CẦU (Respond - kèo không tồn tại) ─

async function testRespondToRequest() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  FLOW 3: PHẢN HỒI YÊU CẦU GHÉP KÈO         ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test: Respond với matchId không tồn tại
  console.log('\n  📌 Test: Respond kèo không tồn tại');
  const r1 = await post('/api/matchmaking/respond', {
    notificationId: 999999,
    requesterId: 2,
    matchId: 999999,
    action: 'accept',
    hostName: 'Test Host'
  });
  assert('MM-RS-01', 'Respond kèo không tồn tại → 404',
    r1.status === 404,
    `Status: ${r1.status}`
  );

  // Test: Thử join và phản hồi kèo đã hết hạn
  console.log('\n  📌 Test: Ghép kèo đã hết hạn');
  const [expiredMatchResult] = await db.query(`
    INSERT INTO matchmaking (host_id, court_name, level, match_date, start_time, capacity, joined_count, price, description)
    VALUES (1, 'Duy Hung Badminton Center', 'Mới chơi', '2020-01-01', '08:00:00', 4, 1, 80000, 'Kèo đã hết hạn test')
  `);
  const expiredMatchId = expiredMatchResult.insertId;

  const expiredJoinRes = await post('/api/matchmaking/join', {
    userId: 2,
    matchId: expiredMatchId,
    hostId: 1,
    senderName: 'User B Test',
    courtName: 'Duy Hung Badminton Center'
  });
  
  assert('MM-JN-EXPIRED', 'Không cho phép ghép kèo đã qua giờ chơi → 400',
    expiredJoinRes.status === 400,
    `Status: ${expiredJoinRes.status}`
  );

  const expiredRespondRes = await post('/api/matchmaking/respond', {
    notificationId: 999999,
    requesterId: 2,
    matchId: expiredMatchId,
    action: 'accept',
    hostName: 'Test Host'
  });

  assert('MM-RS-EXPIRED', 'Chủ kèo không thể chấp nhận yêu cầu của kèo đã hết hạn → 400',
    expiredRespondRes.status === 400,
    `Status: ${expiredRespondRes.status}`
  );

  // Dọn dẹp
  await db.query('DELETE FROM matchmaking WHERE id = ?', [expiredMatchId]);
}

// ── FLOW 4: BOOKING APPROVAL (Owner duyệt booking) ─────────

async function testBookingApproval() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  FLOW 4: OWNER DUYỆT BOOKING                ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Bước 1: Tạo booking mới
  console.log('\n  📌 Bước 1: Tạo booking test');
  const courts = await get('/api/courts/all');
  if (!Array.isArray(courts.body) || courts.body.length === 0) {
    console.log('  ⚠️ Không có sân, bỏ qua test');
    return;
  }

  const court = courts.body[0];
  const bookRes = await post('/api/bookings', {
    user_id: 1,
    court_name: court.name,
    court_address: court.address,
    slot: '19:00 - 20:00',
    booking_date: '2026-06-25',
    price: court.price_per_hour || 80000,
    payment_method: 'Chuyển khoản'
  });

  assert('BK-AP-01', 'Tạo booking thành công', bookRes.status === 200);
  const bookingId = bookRes.body.id;

  if (!bookingId) return;

  // Bước 2: Kiểm tra status mặc định
  console.log('\n  📌 Bước 2: Kiểm tra status mặc định');
  const history = await get('/api/bookings/user/1');
  const booking = history.body.find(b => b.id === bookingId);
  assert('BK-AP-02', 'Status mặc định = "Chờ duyệt"',
    booking && booking.status === 'Chờ duyệt',
    `Status: ${booking ? booking.status : 'not found'}`
  );

  // Bước 3: Owner duyệt booking
  console.log('\n  📌 Bước 3: Owner duyệt booking');
  const approveRes = await put(`/api/bookings/${bookingId}/status`, {
    status: 'Đã duyệt'
  });
  assert('BK-AP-03', 'Duyệt booking → 200', approveRes.status === 200);

  // Bước 4: Kiểm tra status đã thay đổi
  console.log('\n  📌 Bước 4: Kiểm tra status sau khi duyệt');
  const updated = await get('/api/bookings/user/1');
  const updatedBooking = updated.body.find(b => b.id === bookingId);
  assert('BK-AP-04', 'Status chuyển thành "Đã duyệt"',
    updatedBooking && updatedBooking.status === 'Đã duyệt',
    `Status: ${updatedBooking ? updatedBooking.status : 'not found'}`
  );

  // Bước 5: Owner từ chối booking khác
  console.log('\n  📌 Bước 5: Tạo booking khác và từ chối');
  const book2Res = await post('/api/bookings', {
    user_id: 1,
    court_name: court.name,
    court_address: court.address,
    slot: '20:00 - 21:00',
    booking_date: '2026-06-26',
    price: court.price_per_hour || 80000,
    payment_method: 'Tiền mặt'
  });

  if (book2Res.body.id) {
    const rejectRes = await put(`/api/bookings/${book2Res.body.id}/status`, {
      status: 'Từ chối'
    });
    assert('BK-AP-05', 'Từ chối booking → 200', rejectRes.status === 200);

    const rejected = await get('/api/bookings/user/1');
    const rejectedBooking = rejected.body.find(b => b.id === book2Res.body.id);
    assert('BK-AP-06', 'Status chuyển thành "Từ chối"',
      rejectedBooking && rejectedBooking.status === 'Từ chối',
      `Status: ${rejectedBooking ? rejectedBooking.status : 'not found'}`
    );
  }
}

// ── FLOW 5: NOTIFICATION (Thông báo) ────────────────────────

async function testNotifications() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  FLOW 5: HỆ THỐNG THÔNG BÁO (Notifications) ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Bước 1: Lấy thông báo của user 1
  console.log('\n  📌 Bước 1: Lấy danh sách thông báo');
  const notifs = await get('/api/notifications/1');
  assert('NF-01', 'GET /notifications/:userId → 200', notifs.status === 200);
  assert('NF-02', 'Trả về mảng notifications', Array.isArray(notifs.body));

  if (Array.isArray(notifs.body) && notifs.body.length > 0) {
    const notif = notifs.body[0];
    assert('NF-03', 'Notification có title', notif.title !== undefined);
    assert('NF-04', 'Notification có message', notif.message !== undefined);
    assert('NF-05', 'Notification có type', notif.type !== undefined);
    assert('NF-06', 'Notification có created_at', notif.created_at !== undefined);
  }

  // Bước 2: Tạo thông báo mới
  console.log('\n  📌 Bước 2: Tạo thông báo test');
  const createRes = await post('/api/notifications', {
    userId: 1,
    title: '🧪 Test Notification',
    message: 'Đây là thông báo test từ security_test.js',
    type: 'test'
  });
  assert('NF-07', 'Tạo notification → 201', createRes.status === 201);
}

// ── MAIN ────────────────────────────────────────────────────

async function runAllTests() {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  🔄 SHUTTLECOURT - MATCHMAKING & NOTIFICATION TESTS    ║');
  console.log('║  Tương ứng: 02_Flow_Integration_Test.md (Luồng 4-7)    ║');
  console.log('║  Server: http://localhost:3000                          ║');
  console.log('╚══════════════════════════════════════════════════════════╝');

  try {
    // Clean up test data
    await db.query("DELETE FROM bookings WHERE court_name = 'Duy Hung Badminton Center' OR court_name = 'Test'");
    await db.query("DELETE FROM matchmaking WHERE court_name = 'Duy Hung Badminton Center' OR court_name = 'Test'");
    await db.query("DELETE FROM bookings WHERE booking_date IN ('2026-06-25', '2026-06-26')");
    await db.query("DELETE FROM matchmaking_participants WHERE match_id NOT IN (SELECT id FROM matchmaking)");

    const matchId = await testMatchmakingCreate();
    await testJoinRequest(matchId);
    await testRespondToRequest();
    await testBookingApproval();
    await testNotifications();

    console.log('\n══════════════════════════════════════════════');
    console.log(`  📊 KẾT QUẢ: ${passCount}/${totalTests} PASS | ${failCount} FAIL`);
    console.log(`  📈 Tỷ lệ: ${((passCount / totalTests) * 100).toFixed(1)}%`);
    console.log('══════════════════════════════════════════════\n');

    process.exit(failCount > 0 ? 1 : 0);
  } catch (err) {
    console.error('\n❌ Lỗi:', err.message);
    console.log('💡 Đảm bảo server đang chạy + MySQL bật + có user id=1,2');
    process.exit(1);
  }
}

runAllTests();
