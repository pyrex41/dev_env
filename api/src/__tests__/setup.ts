/**
 * Vitest Test Setup
 * Runs before all tests
 */

import { config } from 'dotenv';

// Load test environment variables
config({ path: '.env' });

// Set test environment
process.env.NODE_ENV = 'test';

// Global test setup
beforeAll(async () => {
  // Setup code that runs once before all tests
});

// Global test teardown
afterAll(async () => {
  // Cleanup code that runs once after all tests
});
