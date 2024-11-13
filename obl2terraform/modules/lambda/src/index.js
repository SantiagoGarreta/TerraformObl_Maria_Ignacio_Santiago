const { Pool } = require('pg');

// Configure PostgreSQL connection
const pool = new Pool({
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
    ssl: {
        rejectUnauthorized: false
    }
});

// Function to validate transaction data
const validateTransaction = (transaction) => {
    const requiredFields = [
        'sender_bank_code',
        'sender_account_number',
        'receiver_account_number',
        'amount',
        'currency'
    ];

    const validCurrencies = [
        'USD', 'CAD', 'EUR', 'GBP', 'UYU', 'ARS', 
        'BRL', 'CLP', 'COP', 'PEN', 'PYG', 'MXN'
    ];

    // Check required fields
    for (const field of requiredFields) {
        if (!transaction[field]) {
            throw new Error(`Missing required field: ${field}`);
        }
    }

    // Validate currency
    if (!validCurrencies.includes(transaction.currency)) {
        throw new Error(`Invalid currency: ${transaction.currency}`);
    }

    // Validate amount
    if (isNaN(transaction.amount) || transaction.amount <= 0) {
        throw new Error('Invalid amount');
    }

    return true;
};

// Function to insert a single transaction
const insertTransaction = async (client, transaction) => {
    const query = `
        INSERT INTO transactions (
            transaction_id,
            sender_bank_code,
            sender_account_number,
            receiver_account_number,
            amount,
            currency,
            transaction_date,
            description
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
    `;

    const values = [
        transaction.transaction_id || `TRX-${Date.now()}`,
        transaction.sender_bank_code,
        transaction.sender_account_number,
        transaction.receiver_account_number,
        transaction.amount,
        transaction.currency,
        transaction.transaction_date || new Date().toISOString(),
        transaction.description || ''
    ];

    return client.query(query, values);
};

exports.handler = async (event) => {
    const headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "OPTIONS,POST"
    };

    // Handle CORS preflight request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: headers,
            body: JSON.stringify({ message: "OK" })
        };
    }

    const client = await pool.connect();
    
    try {
        await client.query('BEGIN');
        
        const body = JSON.parse(event.body);
        let results = [];

        // Check if we're receiving a batch of transactions or a single transaction
        if (body.transactions && Array.isArray(body.transactions)) {
            // Process batch transactions
            for (const transaction of body.transactions) {
                validateTransaction(transaction);
                const result = await insertTransaction(client, transaction);
                results.push(result.rows[0]);
            }
        } else {
            // Process single transaction
            validateTransaction(body);
            const result = await insertTransaction(client, body);
            results.push(result.rows[0]);
        }

        await client.query('COMMIT');

        return {
            statusCode: 200,
            headers: headers,
            body: JSON.stringify({
                message: "Transaction(s) processed successfully",
                data: results
            })
        };

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error:', error);
        
        return {
            statusCode: 500,
            headers: headers,
            body: JSON.stringify({
                message: "Error processing transaction(s)",
                error: error.message
            })
        };
        
    } finally {
        client.release();
    }
};