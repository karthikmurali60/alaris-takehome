import express from 'express';
import { Pool } from 'pg';

const publicPort = 8080;
const internalPort = 9090;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'app',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
});

const tenantName = process.env.TENANT_NAME || 'unknown';

// Public endpoint app
const publicApp = express();
publicApp.get('/public', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as current_time, $1 as tenant', [tenantName]);
    res.json({
      message: `Hello from ${tenantName} public endpoint`,
      data: result.rows[0],
      endpoint: 'public'
    });
  } catch (error) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

publicApp.get('/health', (req, res) => {
  res.json({ status: 'healthy', tenant: tenantName });
});

// Internal endpoint app
const internalApp = express();
internalApp.get('/internal', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as current_time, $1 as tenant', [tenantName]);
    res.json({
      message: `Hello from ${tenantName} internal endpoint`,
      data: result.rows[0],
      endpoint: 'internal'
    });
  } catch (error) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

internalApp.get('/health', (req, res) => {
  res.json({ status: 'healthy', tenant: tenantName, endpoint: 'internal' });
});

// Start servers
publicApp.listen(publicPort, () => {
  console.log(`${tenantName} public server running on port ${publicPort}`);
});

internalApp.listen(internalPort, () => {
  console.log(`${tenantName} internal server running on port ${internalPort}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Shutting down gracefully...');
  pool.end();
  process.exit(0);
});
