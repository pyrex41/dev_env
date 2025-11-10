/**
 * Seed Users
 * Creates test user accounts for development
 */

import { Pool } from 'pg';

export async function seedUsers(pool: Pool): Promise<void> {
  console.log('  → Seeding users...');

  const users = [
    {
      email: 'admin@example.com',
      username: 'admin',
      // In production, use proper password hashing (bcrypt, argon2, etc.)
      // This is a placeholder hash for 'password123'
      password_hash: '$2b$10$rBV2kHYW4YW8Y4QZQZQZQO1Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y',
    },
    {
      email: 'john.doe@example.com',
      username: 'johndoe',
      password_hash: '$2b$10$rBV2kHYW4YW8Y4QZQZQZQO1Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y',
    },
    {
      email: 'jane.smith@example.com',
      username: 'janesmith',
      password_hash: '$2b$10$rBV2kHYW4YW8Y4QZQZQZQO1Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y',
    },
    {
      email: 'bob.wilson@example.com',
      username: 'bobwilson',
      password_hash: '$2b$10$rBV2kHYW4YW8Y4QZQZQZQO1Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y',
    },
    {
      email: 'alice.johnson@example.com',
      username: 'alicejohnson',
      password_hash: '$2b$10$rBV2kHYW4YW8Y4QZQZQZQO1Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y2Y',
    },
  ];

  for (const user of users) {
    try {
      await pool.query(
        `INSERT INTO users (email, username, password_hash)
         VALUES ($1, $2, $3)
         ON CONFLICT (email) DO NOTHING`,
        [user.email, user.username, user.password_hash]
      );
    } catch (error) {
      console.error(`    Error seeding user ${user.email}:`, error);
      throw error;
    }
  }

  const result = await pool.query('SELECT COUNT(*) FROM users');
  console.log(`    ✓ ${users.length} users seeded (${result.rows[0].count} total in database)`);
}
