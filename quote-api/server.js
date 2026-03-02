const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { pool } = require('./config/database');
const authRoutes = require('./routes/auth');
const quoteRoutes = require('./routes/quotes');
const authenticateToken = require('./middleware/auth_middleware');
const errorMiddleware = require('./middleware/error_middleware');

const app = express();

// ─── Global Middleware ────────────────────────────────────────────────────────

app.use(cors());
app.use(express.json());

// In server.js — add BEFORE routes
app.use((req, res, next) => {
  console.log('AUTH HEADER:', req.headers['authorization']);
  next();
});

// ─── Routes ───────────────────────────────────────────────────────────────────

// Public — no token needed
app.use('/api/auth', authRoutes); 

// Protected — JWT required
app.use('/api/quotes', authenticateToken, quoteRoutes);

// DB health check
app.get('/api/test', async (req, res, next) => {
  try {
    const [rows] = await pool.query('SELECT 1 + 1 AS solution');
    res.json({ success: true, message: 'DB Connected!', result: rows[0].solution });
  } catch (err) {
    next(err); // passes to error middleware
  }
});

// 404 handler — catches any unmatched routes
app.use((req, res, next) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found.` });
});

// ─── Centralized Error Handler (MUST be last) ─────────────────────────────────

app.use(errorMiddleware);

// ─── Start Server ─────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
});
