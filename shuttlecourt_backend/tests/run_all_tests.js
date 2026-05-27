/**
 * ============================================================
 * MASTER TEST RUNNER: Chạy tất cả test suites
 * 
 * CÁCH CHẠY:
 *   1. Server phải đang chạy: node server.js
 *   2. MySQL (XAMPP) phải bật
 *   3. Chạy: node tests/run_all_tests.js
 * 
 * Hoặc chạy từng file riêng:
 *   node tests/algorithm_test.js
 *   node tests/api_test.js
 *   node tests/flow_test.js
 *   node tests/security_test.js
 *   node tests/matchmaking_flow_test.js
 *   node tests/performance_test.js
 * ============================================================
 */

const { execSync } = require('child_process');
const path = require('path');

const testDir = __dirname;

const testFiles = [
  { file: 'algorithm_test.js', name: '🧮 Algorithm & Logic Tests', needsServer: false },
  { file: 'api_test.js', name: '🌐 API Integration Tests', needsServer: true },
  { file: 'flow_test.js', name: '🔄 Flow Integration Tests', needsServer: true },
  { file: 'security_test.js', name: '🔐 Security Tests', needsServer: true },
  { file: 'matchmaking_flow_test.js', name: '🏸 Matchmaking & Notification Tests', needsServer: true },
  { file: 'performance_test.js', name: '⚡ Performance & Concurrency Tests', needsServer: true },
];

let totalPassed = 0;
let totalFailed = 0;

console.log('╔══════════════════════════════════════════════════════════╗');
console.log('║  🧪 SHUTTLECOURT - MASTER TEST RUNNER                  ║');
console.log('║  Running all backend test suites...                      ║');
console.log('╚══════════════════════════════════════════════════════════╝');
console.log('');

for (const test of testFiles) {
  const filePath = path.join(testDir, test.file);
  console.log(`\n${'═'.repeat(56)}`);
  console.log(`  ▶ Running: ${test.name}`);
  console.log(`    File: ${test.file}`);
  console.log(`${'═'.repeat(56)}`);

  try {
    const output = execSync(`node "${filePath}"`, {
      encoding: 'utf8',
      timeout: 30000,
      stdio: 'pipe',
    });
    console.log(output);

    // Parse results from output
    const match = output.match(/KẾT QUẢ: (\d+)\/(\d+) PASS \| (\d+) FAIL/);
    if (match) {
      totalPassed += parseInt(match[1]);
      totalFailed += parseInt(match[3]);
    }
  } catch (err) {
    console.log(err.stdout || '');
    console.error(`  ⚠️ Test suite finished with errors`);

    // Parse results even from failed tests
    const output = err.stdout || '';
    const match = output.match(/KẾT QUẢ: (\d+)\/(\d+) PASS \| (\d+) FAIL/);
    if (match) {
      totalPassed += parseInt(match[1]);
      totalFailed += parseInt(match[3]);
    }
  }
}

const totalTests = totalPassed + totalFailed;
const rate = totalTests > 0 ? ((totalPassed / totalTests) * 100).toFixed(1) : '0.0';

console.log('\n╔══════════════════════════════════════════════════════════╗');
console.log('║  📊 TỔNG KẾT TẤT CẢ TEST SUITES                       ║');
console.log('╠══════════════════════════════════════════════════════════╣');
console.log(`║  Total Tests: ${totalTests.toString().padEnd(41)}║`);
console.log(`║  Passed:      ${totalPassed.toString().padEnd(41)}║`);
console.log(`║  Failed:      ${totalFailed.toString().padEnd(41)}║`);
console.log(`║  Pass Rate:   ${(rate + '%').padEnd(41)}║`);
console.log('╚══════════════════════════════════════════════════════════╝');

process.exit(totalFailed > 0 ? 1 : 0);
