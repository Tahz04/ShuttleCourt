/**
 * ============================================================
 * BACKEND TEST: API Integration Tests
 * Test thực tế gọi API backend ShuttleCourt
 * 
 * CÁCH CHẠY:
 *   1. Đảm bảo server đang chạy: node server.js
 *   2. Đảm bảo MySQL (XAMPP) đang bật
 *   3. Chạy test: node tests/api_test.js
 * ============================================================
 */

const http = require('http');

const BASE_URL = 'http://localhost:3000';
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
    http.get(`${BASE_URL}${path}`, (res) => {
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

function assert(testName, condition, detail = '') {
  totalTests++;
  if (condition) {
    passCount++;
    console.log(`  ✅ PASS: ${testName}`);
  } else {
    failCount++;
    console.log(`  ❌ FAIL: ${testName} ${detail ? '→ ' + detail : ''}`);
  }
}

// ── TEST SUITES ─────────────────────────────────────────────

async function testAuthAPI() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  1. AUTH API TESTS                           ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test: Đăng ký thiếu thông tin
  const r1 = await post('/api/auth/register', { email: 'test@test.com' });
  assert('Register thiếu thông tin → 400', r1.status === 400);
  assert('Register trả về message lỗi', r1.body.message !== undefined);

  // Test: Login thiếu thông tin
  const r2 = await post('/api/auth/login', {});
  assert('Login thiếu email/password → 400', r2.status === 400);

  // Test: Login email không tồn tại
  const r3 = await post('/api/auth/login', { email: 'notexist@xyz.com', password: '123456' });
  assert('Login email không tồn tại → 400', r3.status === 400);

  // Test: GET owners
  const r4 = await get('/api/auth/owners');
  assert('GET /auth/owners → 200', r4.status === 200);
  assert('Owners trả về mảng', Array.isArray(r4.body));

  // Test: Đổi mật khẩu thiếu thông tin
  const r5 = await post('/api/auth/update-password', {});
  assert('Update password thiếu info → 400', r5.status === 400);
}

async function testCourtsAPI() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  2. COURTS API TESTS                         ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test: Lấy tất cả sân
  const r1 = await get('/api/courts/all');
  assert('GET /courts/all → 200', r1.status === 200);
  assert('Courts trả về mảng', Array.isArray(r1.body));

  if (r1.body.length > 0) {
    const firstCourt = r1.body[0];
    assert('Court có field name', firstCourt.name !== undefined);
    assert('Court có field address', firstCourt.address !== undefined);
    assert('Court có field price_per_hour', firstCourt.price_per_hour !== undefined);

    // Test: Lấy sân theo ID
    const r2 = await get(`/api/courts/${firstCourt.id}`);
    assert('GET /courts/:id → 200', r2.status === 200);
    assert('Court data khớp ID', r2.body.id === firstCourt.id);
  }

  // Test: Court không tồn tại
  const r3 = await get('/api/courts/999999');
  assert('GET /courts/999999 → 404', r3.status === 404);

  // Test: Thêm sân thiếu thông tin
  const r4 = await post('/api/courts/add', { name: 'Test' });
  assert('POST /courts/add thiếu info → 400', r4.status === 400);
}

async function testBookingsAPI() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  3. BOOKINGS API TESTS                       ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test: Tạo booking thiếu thông tin
  const r1 = await post('/api/bookings', { user_id: 1 });
  assert('POST /bookings thiếu fields → 400', r1.status === 400);
  assert('Trả về "Missing required fields"', r1.body.message === 'Missing required fields');

  // Test: Lấy bookings theo user
  const r2 = await get('/api/bookings/user/1');
  assert('GET /bookings/user/1 → 200', r2.status === 200);
  assert('Bookings trả về mảng', Array.isArray(r2.body));

  // Test: Lấy tất cả bookings
  const r3 = await get('/api/bookings/all');
  assert('GET /bookings/all → 200', r3.status === 200);
  assert('All bookings trả về mảng', Array.isArray(r3.body));
}

async function testMatchmakingAPI() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  4. MATCHMAKING API TESTS                    ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test: Tạo kèo thiếu thông tin
  const r1 = await post('/api/matchmaking/create', { hostId: 1 });
  assert('POST /matchmaking/create thiếu info → 400', r1.status === 400);

  // Test: Lấy danh sách kèo
  const r2 = await get('/api/matchmaking/all');
  assert('GET /matchmaking/all → 200', r2.status === 200);
  assert('Matches trả về mảng', Array.isArray(r2.body));

  // Test: Join request thiếu thông tin
  const r3 = await post('/api/matchmaking/join', {});
  assert('POST /matchmaking/join thiếu info → 400', r3.status === 400);
}

async function testProductsAPI() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  5. PRODUCTS/SHOP API TESTS                  ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test: Lấy sản phẩm
  const r1 = await get('/api/products');
  assert('GET /products → 200', r1.status === 200);
  assert('Products trả về mảng', Array.isArray(r1.body));

  if (r1.body.length > 0) {
    const product = r1.body[0];
    assert('Product có field name', product.name !== undefined);
    assert('Product có field price', product.price !== undefined);
    assert('Product có field stock', product.stock !== undefined);
  }
}

async function testReviewsAPI() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  6. REVIEWS API TESTS                        ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test: Tạo review thiếu thông tin
  const r1 = await post('/api/reviews', { comment: 'Test' });
  assert('POST /reviews thiếu info → 400', r1.status === 400);
  assert('Review error có success=false', r1.body.success === false);

  // Test: Reply thiếu nội dung
  const r2 = await put('/api/reviews/999/reply', {});
  assert('PUT /reviews/:id/reply thiếu reply → 400', r2.status === 400);
}

async function testOwnerRequestsAPI() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  7. OWNER REQUESTS API TESTS                 ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Test: Submit request thiếu thông tin
  const r1 = await post('/api/owner-requests/submit', { userId: 1 });
  assert('POST /owner-requests/submit thiếu CCCD → 400', r1.status === 400);

  // Test: Lấy danh sách requests
  const r2 = await get('/api/owner-requests');
  assert('GET /owner-requests → 200', r2.status === 200);
  assert('Requests trả về mảng', Array.isArray(r2.body));
}

// ── MAIN ────────────────────────────────────────────────────

async function runAllTests() {
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║  🧪 SHUTTLECOURT BACKEND - API INTEGRATION TESTS   ║');
  console.log('║  Server: http://localhost:3000                      ║');
  console.log('╚══════════════════════════════════════════════════════╝');

  try {
    await testAuthAPI();
    await testCourtsAPI();
    await testBookingsAPI();
    await testMatchmakingAPI();
    await testProductsAPI();
    await testReviewsAPI();
    await testOwnerRequestsAPI();

    console.log('\n══════════════════════════════════════════════');
    console.log(`  📊 KẾT QUẢ: ${passCount}/${totalTests} PASS | ${failCount} FAIL`);
    console.log(`  📈 Tỷ lệ: ${((passCount / totalTests) * 100).toFixed(1)}%`);
    console.log('══════════════════════════════════════════════\n');

    process.exit(failCount > 0 ? 1 : 0);
  } catch (err) {
    console.error('\n❌ Lỗi kết nối server:', err.message);
    console.log('💡 Đảm bảo server đang chạy: cd shuttlecourt_backend && node server.js');
    process.exit(1);
  }
}

runAllTests();
