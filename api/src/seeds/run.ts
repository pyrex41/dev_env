/**
 * Seed Data Runner
 * Loads test data into the database for development
 */

import { Pool } from 'pg';
import * as dotenv from 'dotenv';
import { seedUsers } from './01-users';
import { seedPosts } from './02-posts';

// Load environment variables
dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function runSeeds() {
  try {
    console.log('🌱 Starting database seeding...');

    // Run seeds in order
    await seedUsers(pool);
    await seedPosts(pool);

    console.log('✅ Seeding completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runSeeds();
