const sql = require('mssql');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: '../.env' });

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_HOST,
    database: process.env.DB_NAME,
    options: {
        encrypt: true,
        trustServerCertificate: true, // For self-signed certificates in dev/local environments
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

const MAX_RETRIES = 60;
const RETRY_DELAY_MS = 5000;

const connectWithRetry = async (retryCount = 0) => {
    try {
        // 1. Connect to master to create the database if it doesn't exist
        const initConfig = { ...config, database: 'master' };
        const masterPool = await new sql.ConnectionPool(initConfig).connect();
        
        // Safely create the database if it doesn't exist
        const result = await masterPool.request().query(`
            SELECT name FROM sys.databases WHERE name = '${config.database}'
        `);
        
        if (result.recordset.length === 0) {
            await masterPool.request().query(`CREATE DATABASE ${config.database}`);
            console.log(`✅ Created Database ${config.database}`);
        }
        await masterPool.close();

        // 2. Now connect to our specific database
        const pool = await new sql.ConnectionPool(config).connect();
        console.log('✅ Connected to MSSQL Database successfully!');

        // 3. Run schema to ensure tables exist
        try {
            const schemaPath = path.join(__dirname, 'schema.sql');
            const schema = fs.readFileSync(schemaPath, 'utf8');
            await pool.request().query(schema);
            console.log('✅ Database schema verified/initialized!');
        } catch (schemaErr) {
            console.error('⚠️ Could not run schema setup or it failed:', schemaErr.message);
        }

        return pool;
    } catch (err) {
        if (retryCount < MAX_RETRIES) {
            console.error(`⚠️ Database connection attempt ${retryCount + 1}/${MAX_RETRIES} failed. Retrying in ${RETRY_DELAY_MS / 1000} seconds...`);
            await new Promise(res => setTimeout(res, RETRY_DELAY_MS));
            return connectWithRetry(retryCount + 1);
        } else {
            console.error('❌ Max retries reached. Database connection permanently failed:', err);
            process.exit(1);
        }
    }
};

// Start the connection process immediately
const poolPromise = connectWithRetry();

module.exports = {
    sql,
    poolPromise
};
