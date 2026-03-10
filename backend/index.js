const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const os = require('os');
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
        const result = await pool.request().query('SELECT * FROM Devices ORDER BY CreatedAt DESC');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

// Get single device by ID
app.get('/api/devices/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('id', sql.Int, id)
            .query('SELECT * FROM Devices WHERE ID = @id');
        if (result.recordset.length === 0) {
            return res.status(404).json({ message: 'Device not found' });
        }
        res.json(result.recordset[0]);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

// Add new device
app.post('/api/devices', async (req, res) => {
    const { name, ip, category, serialNumber, details } = req.body;
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('name', sql.VarChar, name)
            .input('ip', sql.VarChar, ip)
            .input('category', sql.VarChar, category)
            .input('serialNumber', sql.VarChar, serialNumber)
            .input('details', sql.VarChar, details)
            .query('INSERT INTO Devices (Name, IP, Category, SerialNumber, Details) OUTPUT INSERTED.* VALUES (@name, @ip, @category, @serialNumber, @details)');
        res.status(201).json(result.recordset[0]);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

// Update existing device
app.put('/api/devices/:id', async (req, res) => {
    const { id } = req.params;
    const { name, ip, category, serialNumber, details } = req.body;
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('id', sql.Int, id)
            .input('name', sql.VarChar, name)
            .input('ip', sql.VarChar, ip)
            .input('category', sql.VarChar, category)
            .input('serialNumber', sql.VarChar, serialNumber)
            .input('details', sql.VarChar, details)
            .query('UPDATE Devices SET Name = @name, IP = @ip, Category = @category, SerialNumber = @serialNumber, Details = @details WHERE ID = @id');
        if (result.rowsAffected[0] === 0) {
            return res.status(404).json({ message: 'Device not found' });
        }
        res.json({ message: 'Device updated successfully' });
    } catch (err) {
        res.status(500).send(err.message);
    }
});

// Delete device
app.delete('/api/devices/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('id', sql.Int, id)
            .query('DELETE FROM Devices WHERE ID = @id');
        if (result.rowsAffected[0] === 0) {
            return res.status(404).json({ message: 'Device not found' });
        }
        res.json({ message: 'Device deleted successfully' });
    } catch (err) {
        res.status(500).send(err.message);
    }
});

// Ping device to check online status
app.get('/api/status/:ip', async (req, res) => {
    const { ip } = req.params;

    // Validate IP format (basic check)
    const ipRegex = /^(\d{1,3}\.){3}\d{1,3}$/;
    if (!ipRegex.test(ip)) {
        return res.status(400).json({ ip, status: 'invalid', message: 'Invalid IP address format' });
    }

    // Use system ping command (works in Docker Linux containers)
    const pingCmd = `ping -c 2 -W 2 ${ip}`;

    exec(pingCmd, { timeout: 10000 }, async (error, stdout, stderr) => {
        const isOnline = !error;
        const now = new Date();

        // Update device status and lastSeen in DB
        try {
            const pool = await poolPromise;
            await pool.request()
                .input('ip', sql.VarChar, ip)
                .input('status', sql.VarChar, isOnline ? 'online' : 'offline')
                .input('lastSeen', sql.DateTime, isOnline ? now : null)
                .query('UPDATE Devices SET Status = @status, LastSeen = CASE WHEN @lastSeen IS NOT NULL THEN @lastSeen ELSE LastSeen END WHERE IP = @ip');
        } catch (dbErr) {
            console.error('Could not update device status in DB:', dbErr.message);
        }

        res.json({
            ip,
            status: isOnline ? 'online' : 'offline',
            lastCheck: now,
            details: isOnline ? stdout.trim().split('\n').pop() : 'Host unreachable'
        });
    });
});

// Background Task: Ping all devices every 5 minutes
const PING_INTERVAL = 5 * 60 * 1000; // 5 minutes in milliseconds

async function pingDeviceAndUpdateDB(ip) {
    if (!ip) return;
    return new Promise((resolve) => {
        const pingCmd = `ping -c 2 -W 2 ${ip}`;
        exec(pingCmd, { timeout: 10000 }, async (error, stdout, stderr) => {
            const isOnline = !error;
            const now = new Date();
            try {
                const pool = await poolPromise;
                await pool.request()
                    .input('ip', sql.VarChar, ip)
                    .input('status', sql.VarChar, isOnline ? 'online' : 'offline')
                    .input('lastSeen', sql.DateTime, isOnline ? now : null)
                    .query('UPDATE Devices SET Status = @status, LastSeen = CASE WHEN @lastSeen IS NOT NULL THEN @lastSeen ELSE LastSeen END WHERE IP = @ip');
            } catch (dbErr) {
                console.error(`Could not update device status for ${ip} in DB:`, dbErr.message);
            }
            resolve(isOnline);
        });
    });
}

function startPeriodicPings() {
    console.log('⏱️  Starting background ping cron job (every 5 minutes)...');
    setInterval(async () => {
        try {
            const pool = await poolPromise;
            const result = await pool.request().query('SELECT IP FROM Devices WHERE IP IS NOT NULL AND IP != \'\'');
            const devices = result.recordset;
            if (devices.length > 0) {
                console.log(`[Cron] Pinging ${devices.length} devices...`);
                // Process in parallel to avoid long blocking
                await Promise.all(devices.map(d => pingDeviceAndUpdateDB(d.IP)));
                console.log(`[Cron] Background ping complete.`);
            }
        } catch (err) {
            console.error('[Cron] Error during periodic ping:', err.message);
        }
    }, PING_INTERVAL);
}

// Start the cron job
startPeriodicPings();

app.listen(port, () => {
    const networkInterfaces = os.networkInterfaces();
    let localIp = 'localhost';
    
    for (const interfaceName in networkInterfaces) {
        const interfaces = networkInterfaces[interfaceName];
        for (const iface of interfaces) {
            if (!iface.internal && iface.family === 'IPv4') {
                localIp = iface.address;
            }
        }
    }

    console.log('====================================');
    console.log(`🚀 Backend server is up and running!`);
    console.log(`🌍 Local Access:   http://localhost:${port}`);
    console.log(`📡 Network Access: http://${localIp}:${port}`);
    console.log('====================================');
});
