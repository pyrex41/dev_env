import express, { Request, Response } from 'express';
import cors from 'cors';
import { Pool } from 'pg';
import { createClient } from 'redis';

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

// Initialize connections
async function initializeConnections() {
  try {
    // Test PostgreSQL connection
    await pool.query('SELECT NOW()');
    console.log('✓ Connected to PostgreSQL');

    // Connect to Redis
    await redisClient.connect();
    console.log('✓ Connected to Redis');
  } catch (error) {
    console.error('Failed to initialize connections:', error);
    process.exit(1);
  }
}

// Health check endpoint
app.get('/health', async (req: Request, res: Response) => {
  try {
    // Check database connection
    await pool.query('SELECT 1');

    // Check Redis connection
    await redisClient.ping();

    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        database: 'connected',
        redis: 'connected',
      },
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// Example API endpoint
app.get('/api/status', (req: Request, res: Response) => {
  res.json({
    message: 'Wander API is running',
    version: '1.0.0',
    environment: process.env.NODE_ENV,
  });
});

// Start server
async function startServer() {
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
