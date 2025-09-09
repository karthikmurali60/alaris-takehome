import express from 'express';
import { Pool } from 'pg';

const publicPort = 8080;
const internalPort = 9090;

const dbConfig = {
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
};

console.log('Database configuration:', {
  host: dbConfig.host,
  port: dbConfig.port,
  database: dbConfig.database,
  user: dbConfig.user
});

const pool = new Pool(dbConfig);

// Test database connection on startup
pool.connect()
  .then(client => {
    console.log('✅ Database connection successful');
    return client.query('SELECT NOW()')
      .then(result => {
        console.log('Database time:', result.rows[0].now);
        client.release();
      });
  })
  .catch(err => {
    console.error('❌ Database connection failed:', err.message);
    console.error('Connection details:', {
      host: dbConfig.host,
      port: dbConfig.port,
      database: dbConfig.database,
      user: dbConfig.user
    });
  });

const tenantName = process.env.TENANT_NAME;

// Public endpoint app
const publicApp = express();
publicApp.get('/public', async (req, res) => {
  try {
    console.log(`Public endpoint called for tenant: ${tenantName}`);
    
    // Test basic connection first
    const client = await pool.connect();
    console.log('Database client connected successfully');
    
    try {
      const result = await client.query('SELECT NOW() as current_time, $1 as tenant', [tenantName]);
      console.log('Query executed successfully');
      
      res.json({
        message: `Hello from ${tenantName} public endpoint`,
        data: result.rows[0],
        endpoint: 'public',
        status: 'success'
      });
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Database error in /public endpoint:', error);
    res.status(500).json({ 
      error: 'Database connection failed',
      details: error instanceof Error ? error.message : 'Unknown error',
      tenant: tenantName,
      timestamp: new Date().toISOString()
    });
  }
});

publicApp.get('/health', (req, res) => {
  // Health check without database dependency
  res.json({ 
    status: 'healthy', 
    tenant: tenantName,
    timestamp: new Date().toISOString(),
    environment: {
      DB_HOST: process.env.DB_HOST,
      DB_PORT: process.env.DB_PORT,
      DB_NAME: process.env.DB_NAME,
      DB_USER: process.env.DB_USER,
      DB_PASSWORD_SET: !!process.env.DB_PASSWORD
    }
  });
});

// Database health check endpoint
publicApp.get('/db-health', async (req, res) => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT 1 as health_check, NOW() as db_time');
    client.release();
    
    res.json({
      status: 'database_healthy',
      tenant: tenantName,
      db_response: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Database health check failed:', error);
    res.status(500).json({
      status: 'database_unhealthy',
      tenant: tenantName,
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    });
  }
});

// Internal endpoint app
const internalApp = express();
internalApp.get('/internal', async (req, res) => {
  try {
    console.log(`Internal endpoint called for tenant: ${tenantName}`);
    const result = await pool.query('SELECT NOW() as current_time, $1 as tenant', [tenantName]);
    res.json({
      message: `Hello from ${tenantName} internal endpoint`,
      data: result.rows[0],
      endpoint: 'internal',
      status: 'success'
    });
  } catch (error) {
    console.error('Database error in /internal endpoint:', error);
    res.status(500).json({ 
      error: 'Database connection failed',
      details: error instanceof Error ? error.message : 'Unknown error',
      tenant: tenantName,
      timestamp: new Date().toISOString()
    });
  }
});

internalApp.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    tenant: tenantName, 
    endpoint: 'internal',
    timestamp: new Date().toISOString()
  });
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
