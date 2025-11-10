/**
 * Health Endpoint Tests
 * Tests the /health endpoint functionality
 */

import { describe, it, expect } from 'vitest';

describe('Health Endpoint', () => {
  const API_URL = process.env.API_URL || 'http://localhost:8000';

  it('should return healthy status', async () => {
    const response = await fetch(`${API_URL}/health`);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toHaveProperty('status');
    expect(data.status).toBe('healthy');
  });

  it('should include timestamp', async () => {
    const response = await fetch(`${API_URL}/health`);
    const data = await response.json();

    expect(data).toHaveProperty('timestamp');
    expect(typeof data.timestamp).toBe('string');
  });

  it('should report database connection status', async () => {
    const response = await fetch(`${API_URL}/health`);
    const data = await response.json();

    expect(data).toHaveProperty('services');
    expect(data.services).toHaveProperty('database');
    expect(data.services.database).toBe('connected');
  });

  it('should report redis connection status', async () => {
    const response = await fetch(`${API_URL}/health`);
    const data = await response.json();

    expect(data).toHaveProperty('services');
    expect(data.services).toHaveProperty('redis');
    expect(data.services.redis).toBe('connected');
  });
});
