const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
require('dotenv').config();

const router = express.Router();

// ---------------------------------------------------------
// 1. SETUP ROUTE: Use this ONCE to create your two users.
// After you create them, you can delete or comment this out.
// ---------------------------------------------------------
router.post('/register', async (req, res) => {
    const { username, password } = req.body;

    try {
        // Hash the password with 10 salt rounds
        const hashedPassword = await bcrypt.hash(password, 10);

        // Insert into database
        const [result] = await pool.query(
            'INSERT INTO users (username, password_hash) VALUES (?, ?)', 
            [username, hashedPassword]
        );

        res.status(201).json({ message: 'User created successfully!', userId: result.insertId });
    } catch (err) {
        if (err.code === 'ER_DUP_ENTRY') {
            return res.status(400).json({ error: 'Username already exists' });
        }
        res.status(500).json({ error: 'Database error', details: err.message });
    }
});

// ---------------------------------------------------------
// 2. LOGIN ROUTE: Flutter calls this to get the JWT Token
// ---------------------------------------------------------
router.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        // Find user in database
        const [users] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
        
        if (users.length === 0) {
            return res.status(401).json({ error: 'Invalid username or password' });
        }

        const user = users[0];

        // Compare the plain text password with the hashed password in DB
        const isMatch = await bcrypt.compare(password, user.password_hash);

        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid username or password' });
        }

        // Generate JWT Token (Expires in 24 hours)
        const token = jwt.sign(
            { id: user.id, username: user.username },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            message: 'Login successful',
            token: token,
            user: { id: user.id, username: user.username }
        });

    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Server error' });x``
    }
});

module.exports = router;
