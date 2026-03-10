const express = require('express');
const cors = require('cors');
const { poolPromise, sql } = require('./db');
require('dotenv').config({ path: '../.env' });

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Get all devices
app.get('/api/devices', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query('SELECT * FROM Devices');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

// Add new device
app.post('/api/devices', async (req, res) => {
    const { name, ip, category, serialNumber, details } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('name', sql.VarChar, name)
            .input('ip', sql.VarChar, ip)
            .input('category', sql.VarChar, category)
            .input('serialNumber', sql.VarChar, serialNumber)
            .input('details', sql.VarChar, details)
            .query('INSERT INTO Devices (Name, IP, Category, SerialNumber, Details) VALUES (@name, @ip, @category, @serialNumber, @details)');
        res.status(201).send('Device added successfully');
    } catch (err) {
        res.status(500).send(err.message);
    }
});

// Health check / Ping
app.get('/api/status/:ip', async (req, res) => {
    const { ip } = req.params;
    // In a real scenario, you'd use a ping library. For now, we'll simulate or just return OK.
    // To be implemented: actual ping logic
    res.json({ ip, status: 'online', lastCheck: new Date() });
});

app.listen(port, () => {
    console.log(`Backend server running on port ${port}`);
});
