import http from 'k6/http';
import { check, sleep } from 'k6';

// Load Configuration for 50 Users
export const options = {
  // Scenario: Ramp-up -> Sustained load (50 VUs) -> Ramp-down
  stages: [
    { duration: '30s', target: 10 },  // Warm-up: Ramp up to 10 users in 30s
    { duration: '1m', target: 50 },   // High Load: Maintain 50 concurrent users for 1 minute
    { duration: '30s', target: 0 },   // Cooldown: Ramp down to 0 gracefully
  ],
  // Acceptance Criteria (Quality Gate)
  thresholds: {
    // 95% of requests must respond in less than 2 seconds.
    // (Threshold slightly raised as latency might increase with 50 users)
    http_req_duration: ['p(95)<2000'], 
    // Less than 1% failed requests allowed (status 500, timeouts, etc.)
    http_req_failed: ['rate<0.01'],
  },
  userAgent: 'DermaTech-LoadTest-Bot/1.0',
};

export default function () {
  // 1. Get the URL (QA or PROD) from the Workflow environment variables
  const BASE_URL = __ENV.API_URL;

  // Safety check in case we forgot to define the variable
  if (!BASE_URL) {
    console.error('❌ CRITICAL ERROR: API_URL variable is not defined');
    check(false, { 'API_URL defined': (v) => v === true });
    return;
  }

  // 2. Make the request
  // If your API has a lightweight endpoint like /health or /api/v1/status, use that.
  // Otherwise, hit the root.
  const res = http.get(BASE_URL);

  // 3. Validations (Checks)
  check(res, {
    'status is 200': (r) => r.status === 200,
    // Verify it is fast (optional, since we already have the global threshold)
    'response time < 2s': (r) => r.timings.duration < 2000,
  });

  // 4. "Pacing": Wait between 0.5 and 1.5 seconds between requests
  // This simulates the user reading or thinking, preventing artificial saturation.
  sleep(Math.random() * 1 + 0.5);
}