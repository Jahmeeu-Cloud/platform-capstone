const express = require('express');
const { Pool } = require('pg');

const app = express();

const port = Number(process.env.PORT || 5000);

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASS,
  port: Number(process.env.DB_PORT || 5432),
});

// Liveness probe:
// Confirms the Node.js process is alive.
app.get('/health/live', (req, res) => {
  res.status(200).json({
    status: 'alive',
  });
});

// Readiness probe:
// Confirms the application can reach PostgreSQL.
app.get('/health/ready', async (req, res) => {
  try {
    await pool.query('SELECT 1');

    res.status(200).json({
      status: 'ready',
      database: 'connected',
    });
  } catch (error) {
    console.error('Readiness check failed:', error.message);

    res.status(503).json({
      status: 'not_ready',
      database: 'disconnected',
    });
  }
});

app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');

    res.json({
      message: 'E-Commerce backend is running',
      databaseTime: result.rows[0].now,
    });
  } catch (error) {
    console.error('Database query failed:', error.message);

    res.status(500).json({
      error: 'Database query failed',
    });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Backend running on port ${port}`);
});
