import http from 'k6/http';
import { check, sleep } from 'k6';

// --- CONFIGURATION ---
export const options = {
  // Scenario: Ramp-up -> Sustained Load (20 VUs) -> Ramp-down
  stages: [
    { duration: '15s', target: 5 },   // Phase 1: Warm-up
    { duration: '1m', target: 20 },   // Phase 2: Sustained Load (Reduced to 20 users)
    { duration: '15s', target: 0 },   // Phase 3: Cooldown
  ],
  thresholds: {
    // 95% of requests must complete within 2s
    http_req_duration: ['p(95)<2000'],
    // Failure rate must be less than 1%
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const BASE_URL = __ENV.API_URL;

  // 1. Validation: Ensure Environment Variable exists
  if (!BASE_URL) {
    console.error(' CRITICAL: API_URL environment variable is missing.');
    check(false, { 'Configuration valid': (v) => v === true });
    return;
  }

  // 2. Request Setup: Mimic a real browser to bypass WAF/Cloudflare bot detection
  const params = {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Upgrade-Insecure-Requests': '1',
    },
  };

  // 3. Execution
  const res = http.get(BASE_URL, params);

  // 4. Diagnostics: Log detailed error if status is not 200 OK
  if (res.status !== 200) {
    console.warn(` Request Failed: Status [${res.status}] | URL: ${BASE_URL}`);
    // Optional: Print first 100 chars of body to identify WAF block messages
    if (res.body) {
      console.warn(` Body Preview: ${res.body.toString().substring(0, 100)}...`);
    }
  }

  // 5. Assertions
  check(res, {
    'status is 200': (r) => r.status === 200,
    'duration < 2s': (r) => r.timings.duration < 2000,
  });

  // 6. Pacing: Randomized sleep to simulate human behavior
  sleep(Math.random() * 1 + 0.5);
}