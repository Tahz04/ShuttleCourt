/**
 * ============================================================
 * BACKEND TEST: Performance & Concurrency Tests
 * Tương ứng: tests_shuttlecourt/06_Performance_Test.md
 * 
 * CÁCH CHẠY:
 *   1. Server phải đang chạy (node server.js)
 *   2. MySQL (XAMPP) phải bật
 *   3. Chạy: node tests/performance_test.js
 * ============================================================
 */

const http = require('http');

let passCount = 0;
let failCount = 0;
let totalTests = 0;

// ── HELPERS ──────────────────────────────────────────────────

function post(path, data) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const body = JSON.stringify(data);
    const options = {
      hostname: 'localhost', port: 3000, path, method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };
    const req = http.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => responseBody += chunk);
      res.on('end', () => {
        const duration = Date.now() - start;
        try { resolve({ status: res.statusCode, body: JSON.parse(responseBody), duration }); }
        catch { resolve({ status: res.statusCode, body: responseBody, duration }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function get(path) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    http.get(`http://localhost:3000${path}`, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        const duration = Date.now() - start;
        try { resolve({ status: res.statusCode, body: JSON.parse(body), duration }); }
        catch { resolve({ status: res.statusCode, body, duration }); }
      });
    }).on('error', reject);
  });
}

function put(path, data) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const body = JSON.stringify(data);
    const options = {
      hostname: 'localhost', port: 3000, path, method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };
    const req = http.request(options, (res) => {
      let rb = '';
      res.on('data', (chunk) => rb += chunk);
      res.on('end', () => {
        const duration = Date.now() - start;
        try { resolve({ status: res.statusCode, body: JSON.parse(rb), duration }); }
        catch { resolve({ status: res.statusCode, body: rb, duration }); }
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

// ── 1. THỜI GIAN PHẢN HỒI API (Response Time) ──────────────

async function testAPIResponseTime() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  1. THỜI GIAN PHẢN HỒI API (Response Time)   ║');
  console.log('╚══════════════════════════════════════════════╝');

  // PER-AP-01: POST /auth/login < 500ms
  const r1 = await post('/api/auth/login', {
    email: 'test@notexist.com', password: '123456'
  });
  assert('PER-AP-01', `POST /auth/login < 500ms (${r1.duration}ms)`,
    r1.duration < 500, `${r1.duration}ms`
  );

  // PER-AP-03: GET /courts/all < 300ms
  const r2 = await get('/api/courts/all');
  assert('PER-AP-03', `GET /courts/all < 300ms (${r2.duration}ms)`,
    r2.duration < 300, `${r2.duration}ms`
  );

  // PER-AP-04: GET /courts/:id < 200ms
  if (Array.isArray(r2.body) && r2.body.length > 0) {
    const r3 = await get(`/api/courts/${r2.body[0].id}`);
    assert('PER-AP-04', `GET /courts/:id < 200ms (${r3.duration}ms)`,
      r3.duration < 200, `${r3.duration}ms`
    );
  }

  // PER-AP-06: GET /bookings/user/:userId < 300ms
  const r4 = await get('/api/bookings/user/1');
  assert('PER-AP-06', `GET /bookings/user/1 < 300ms (${r4.duration}ms)`,
    r4.duration < 300, `${r4.duration}ms`
  );

  // PER-AP-07: GET /bookings/all < 500ms
  const r5 = await get('/api/bookings/all');
  assert('PER-AP-07', `GET /bookings/all < 500ms (${r5.duration}ms)`,
    r5.duration < 500, `${r5.duration}ms`
  );

  // PER-AP-08: POST /matchmaking/create < 300ms (with error)
  const r6 = await post('/api/matchmaking/create', { hostId: 1 });
  assert('PER-AP-08', `POST /matchmaking/create < 300ms (${r6.duration}ms)`,
    r6.duration < 300, `${r6.duration}ms`
  );

  // PER-AP-09: GET /matchmaking/all < 300ms
  const r7 = await get('/api/matchmaking/all');
  assert('PER-AP-09', `GET /matchmaking/all < 300ms (${r7.duration}ms)`,
    r7.duration < 300, `${r7.duration}ms`
  );

  // PER-AP-11: GET /products < 300ms
  const r8 = await get('/api/products');
  assert('PER-AP-11', `GET /products < 300ms (${r8.duration}ms)`,
    r8.duration < 300, `${r8.duration}ms`
  );

  // PER-AP-12: GET /reviews/court/:courtId < 300ms
  if (Array.isArray(r2.body) && r2.body.length > 0) {
    const r9 = await get(`/api/reviews/court/${r2.body[0].id}`);
    assert('PER-AP-12', `GET /reviews/court/:id < 300ms (${r9.duration}ms)`,
      r9.duration < 300, `${r9.duration}ms`
    );
  }
}

// ── 2. TẢI ĐỒNG THỜI (Concurrency) ─────────────────────────

async function testConcurrency() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  2. TẢI ĐỒNG THỜI (Concurrency Tests)       ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Lấy sân để dùng cho booking test
  const courts = await get('/api/courts/all');
  if (!Array.isArray(courts.body) || courts.body.length === 0) {
    console.log('  ⚠️ Không có sân, bỏ qua test concurrency');
    return;
  }
  const court = courts.body[0];

  // PER-CC-01: 5 booking đồng thời
  console.log('\n  📌 PER-CC-01: 5 booking đồng thời');
  const bookingPromises = [];
  for (let i = 0; i < 5; i++) {
    bookingPromises.push(post('/api/bookings', {
      user_id: 1,
      court_name: court.name,
      court_address: court.address,
      slot: `${8 + i}:00 - ${9 + i}:00`,
      booking_date: '2026-07-01',
      price: court.price_per_hour || 80000,
      payment_method: 'Tiền mặt'
    }));
  }

  const bookingResults = await Promise.all(bookingPromises);
  const allBookingsOk = bookingResults.every(r => r.status === 200);
  assert('PER-CC-01', `5 booking đồng thời → tất cả 200`,
    allBookingsOk,
    `Results: ${bookingResults.map(r => r.status).join(', ')}`
  );

  // PER-CC-02: 5 GET đồng thời
  console.log('\n  📌 PER-CC-02: 5 request GET đồng thời');
  const getPromises = [
    get('/api/courts/all'),
    get('/api/bookings/all'),
    get('/api/matchmaking/all'),
    get('/api/products'),
    get('/api/auth/owners'),
  ];

  const getResults = await Promise.all(getPromises);
  const allGetsOk = getResults.every(r => r.status === 200);
  assert('PER-CC-02', '5 GET requests đồng thời → tất cả 200',
    allGetsOk,
    `Results: ${getResults.map(r => r.status).join(', ')}`
  );

  // Tổng thời gian
  const maxDuration = Math.max(...getResults.map(r => r.duration));
  assert('PER-CC-03', `Max response time < 1000ms (${maxDuration}ms)`,
    maxDuration < 1000, `${maxDuration}ms`
  );
}

// ── 3. STRESS TEST (Kiểm tra tải) ──────────────────────────

async function testStress() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  3. STRESS TEST (Sequential Rapid Requests)  ║');
  console.log('╚══════════════════════════════════════════════╝');

  // 10 request liên tiếp nhanh
  console.log('\n  📌 10 request GET liên tiếp');
  const start = Date.now();
  const results = [];
  for (let i = 0; i < 10; i++) {
    const r = await get('/api/courts/all');
    results.push(r);
  }
  const totalTime = Date.now() - start;
  const avgTime = Math.round(totalTime / 10);

  const allOk = results.every(r => r.status === 200);
  assert('PER-ST-01', '10 request liên tiếp → tất cả 200',
    allOk,
    `Failed: ${results.filter(r => r.status !== 200).length}`
  );
  assert('PER-ST-02', `Trung bình response < 200ms (${avgTime}ms)`,
    avgTime < 200, `Avg: ${avgTime}ms`
  );
  assert('PER-ST-03', `Tổng 10 request < 3000ms (${totalTime}ms)`,
    totalTime < 3000, `Total: ${totalTime}ms`
  );
}

// ── 4. CONNECTION POOL TEST ─────────────────────────────────

async function testConnectionPool() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  4. CONNECTION POOL (MySQL Pool)             ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test bằng cách gửi nhiều request đồng thời để kiểm tra pool
  const promises = [];
  for (let i = 0; i < 10; i++) {
    promises.push(get('/api/courts/all'));
  }

  const results = await Promise.all(promises);
  const allOk = results.every(r => r.status === 200);
  assert('PER-CP-01', '10 request đồng thời → MySQL pool xử lý tốt',
    allOk,
    `Failed: ${results.filter(r => r.status !== 200).length}`
  );

  // Kiểm tra server không crash sau nhiều request
  const healthCheck = await get('/api/courts/all');
  assert('PER-CP-02', 'Server vẫn healthy sau stress test',
    healthCheck.status === 200
  );
}

// ── MAIN ────────────────────────────────────────────────────

async function runAllTests() {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  ⚡ SHUTTLECOURT - PERFORMANCE & CONCURRENCY TESTS     ║');
  console.log('║  Tương ứng: tests_shuttlecourt/06_Performance_Test.md   ║');
  console.log('║  Server: http://localhost:3000                          ║');
  console.log('╚══════════════════════════════════════════════════════════╝');

  try {
    await testAPIResponseTime();
    await testConcurrency();
    await testStress();
    await testConnectionPool();

    console.log('\n══════════════════════════════════════════════');
    console.log(`  📊 KẾT QUẢ: ${passCount}/${totalTests} PASS | ${failCount} FAIL`);
    console.log(`  📈 Tỷ lệ: ${((passCount / totalTests) * 100).toFixed(1)}%`);
    console.log('══════════════════════════════════════════════\n');

    process.exit(failCount > 0 ? 1 : 0);
  } catch (err) {
    console.error('\n❌ Lỗi:', err.message);
    console.log('💡 Đảm bảo server đang chạy + MySQL bật');
    process.exit(1);
  }
}

runAllTests();
