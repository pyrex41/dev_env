import express, { Request, Response } from 'express';
import cors from 'cors';
import { Pool } from 'pg';
import { createClient } from 'redis';
import path from 'path';
import runner from 'node-pg-migrate';

const app = express();
const PORT = process.env.API_PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Redis connection
const redisClient = createClient({
  url: process.env.REDIS_URL,
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));

// Retry helper function
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  options: {
    retries: number;
    delay: number;
    serviceName: string;
  }
): Promise<T> {
  const { retries, delay, serviceName } = options;
  let lastError: Error | unknown;

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt < retries) {
        console.log(`⚠ ${serviceName} connection failed (attempt ${attempt}/${retries}). Retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError;
}

// Run database migrations
async function runMigrations() {
  try {
    console.log('🔄 Running database migrations...');

    await retryWithBackoff(
      async () => {
        await runner({
          databaseUrl: process.env.DATABASE_URL!,
          migrationsTable: 'pgmigrations',
          dir: path.join(__dirname, 'migrations'),
          direction: 'up',
          count: Infinity,
          log: (msg: string) => console.log(`   ${msg}`),
        });
      },
      {
        retries: 10,
        delay: 3000,
        serviceName: 'Database migrations'
      }
    );

    console.log('✓ Migrations completed successfully');
  } catch (error) {
    console.error('\n❌ Database migration failed');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (error instanceof Error) {
      console.error('Error:', error.message);

      console.error('\n💡 Troubleshooting:');
      console.error('  1. Check the migration files in api/src/migrations/');
      console.error('  2. View detailed logs:');
      console.error('     make logs-api');
      console.error('  3. Rollback the last migration:');
      console.error('     make migrate-rollback');
      console.error('  4. Reset the database (WARNING: destroys data):');
      console.error('     make reset');
    }

    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    throw error;
  }
}

// Initialize connections
async function initializeConnections() {
  try {
    // Test PostgreSQL connection with retries
    await retryWithBackoff(
      async () => {
        await pool.query('SELECT NOW()');
      },
      {
        retries: 5,
        delay: 2000,
        serviceName: 'PostgreSQL'
      }
    );
    console.log('✓ Connected to PostgreSQL');

    // Connect to Redis with retries (but don't fail if it's unavailable)
    try {
      await retryWithBackoff(
        async () => {
          await redisClient.connect();
        },
        {
          retries: 3,
          delay: 1000,
          serviceName: 'Redis'
        }
      );
      console.log('✓ Connected to Redis');
    } catch (redisError) {
      console.warn('⚠ Redis connection failed. Continuing without cache...');
      console.warn('  To fix: Check if Redis is running and credentials are correct');
      // Continue without Redis - graceful degradation
    }
  } catch (error) {
    console.error('\n❌ Failed to initialize database connection');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (error instanceof Error) {
      console.error('Error:', error.message);

      // Provide helpful troubleshooting hints
      if (error.message.includes('ECONNREFUSED')) {
        console.error('\n💡 Troubleshooting:');
        console.error('  1. Check if PostgreSQL container is running:');
        console.error('     docker ps | grep postgres');
        console.error('  2. Verify connection string in .env file');
        console.error('  3. Try restarting services:');
        console.error('     make reset');
      } else if (error.message.includes('password authentication failed')) {
        console.error('\n💡 Troubleshooting:');
        console.error('  1. Check POSTGRES_PASSWORD in .env file');
        console.error('  2. Ensure .env doesn\'t have CHANGE_ME values:');
        console.error('     make validate-secrets');
      } else if (error.message.includes('database') && error.message.includes('does not exist')) {
        console.error('\n💡 Troubleshooting:');
        console.error('  1. Check POSTGRES_DB in .env file');
        console.error('  2. Try resetting the environment:');
        console.error('     make reset');
      }
    }

    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    process.exit(1);
  }
}

// Health check endpoint
app.get('/health', async (_req: Request, res: Response): Promise<void> => {
  const health: {
    status: 'healthy' | 'degraded' | 'unhealthy';
    timestamp: string;
    services: {
      database: string;
      redis: string;
    };
  } = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      database: 'unknown',
      redis: 'unknown',
    },
  };

  try {
    // Check database connection (critical)
    await pool.query('SELECT 1');
    health.services.database = 'connected';
  } catch (error) {
    health.status = 'unhealthy';
    health.services.database = 'disconnected';
    res.status(503).json(health);
    return;
  }

  try {
    // Check Redis connection (non-critical)
    if (redisClient.isOpen) {
      await redisClient.ping();
      health.services.redis = 'connected';
    } else {
      health.services.redis = 'disconnected';
      health.status = 'degraded'; // Still functional without Redis
    }
  } catch (error) {
    health.services.redis = 'disconnected';
    health.status = 'degraded'; // Still functional without Redis
  }

  const statusCode = health.status === 'healthy' ? 200 : 206; // 206 = Partial Content (degraded)
  res.status(statusCode).json(health);
});

// Example API endpoint
app.get('/api/status', (_req: Request, res: Response) => {
  res.json({
    message: 'Wander API is running',
    version: '1.0.0',
    environment: process.env.NODE_ENV,
  });
});

// Get all users
app.get('/api/users', async (_req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(
      'SELECT id, email, username, created_at FROM users ORDER BY created_at DESC'
    );
    res.json({ users: result.rows });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get all posts with user information
app.get('/api/posts', async (_req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(`
      SELECT
        p.id,
        p.title,
        p.content,
        p.status,
        p.created_at,
        u.username,
        u.email
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE p.status = 'published'
      ORDER BY p.created_at DESC
    `);
    res.json({ posts: result.rows });
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

// Start server
async function startServer() {
  // Run migrations first
  await runMigrations();

  // Then initialize connections
  await initializeConnections();

  app.listen(PORT, () => {
    console.log(`🚀 API server running on http://localhost:${PORT}`);
    console.log(`🔍 Health check available at http://localhost:${PORT}/health`);
    console.log(`🐛 Debug port available at localhost:${process.env.DEBUG_PORT || 9229}`);
  });
}

startServer().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  await pool.end();
  await redisClient.quit();
  process.exit(0);
});
