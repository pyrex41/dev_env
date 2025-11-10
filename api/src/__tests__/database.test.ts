/**
 * Database Connection Tests
 * Tests database connectivity and basic operations
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';

describe('Database Connection', () => {
  let pool: Pool;

  beforeAll(() => {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
  });

  afterAll(async () => {
    await pool.end();
  });

  it('should connect to the database', async () => {
    const result = await pool.query('SELECT NOW()');
    expect(result.rows).toHaveLength(1);
    expect(result.rows[0]).toHaveProperty('now');
  });

  it('should have migrations table', async () => {
    const result = await pool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_name = 'pgmigrations'
    `);
    expect(result.rows).toHaveLength(1);
    expect(result.rows[0].table_name).toBe('pgmigrations');
  });

  it('should have users table', async () => {
    const result = await pool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_name = 'users'
    `);
    expect(result.rows).toHaveLength(1);
    expect(result.rows[0].table_name).toBe('users');
  });

  it('should have posts table', async () => {
    const result = await pool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_name = 'posts'
    `);
    expect(result.rows).toHaveLength(1);
    expect(result.rows[0].table_name).toBe('posts');
  });

  it('should have foreign key constraint on posts', async () => {
    const result = await pool.query(`
      SELECT constraint_name
      FROM information_schema.table_constraints
      WHERE table_name = 'posts'
      AND constraint_type = 'FOREIGN KEY'
    `);
    expect(result.rows.length).toBeGreaterThan(0);
  });
});
