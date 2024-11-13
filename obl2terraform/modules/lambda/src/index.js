const AWS = require('aws-sdk');
const s3 = new AWS.S3();

const acceptedCurrencies = [
    "USD", "CAD", "EUR", "GBP", "UYU", "ARS", 
    "BRL", "CLP", "COP", "PEN", "PYG", "MXN"
];


const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'OPTIONS,POST',
    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Origin'
};


const validateTransaction = (transaction, index = 0) => {
    const errors = [];
    const {
        transaction_id, sender_bank_code, sender_account_number,
        receiver_account_number, amount, currency, transaction_date, description
    } = transaction;

    if (!transaction_id || typeof transaction_id !== 'string') {
        errors.push(`Transacción ${index}: ID de transacción inválido.`);
    }
    if (!sender_bank_code || typeof sender_bank_code !== 'string') {
        errors.push(`Transacción ${index}: Código de banco remitente inválido.`);
    }
    if (!sender_account_number || typeof sender_account_number !== 'string') {
        errors.push(`Transacción ${index}: Número de cuenta del remitente inválido.`);
    }
    if (!receiver_account_number || typeof receiver_account_number !== 'string') {
        errors.push(`Transacción ${index}: Número de cuenta del receptor inválido.`);
    }
    if (typeof amount !== 'number' || amount <= 0) {
        errors.push(`Transacción ${index}: Monto inválido.`);
    }
    if (!acceptedCurrencies.includes(currency)) {
        errors.push(`Transacción ${index}: Moneda no aceptada (${currency}).`);
    }
    if (!transaction_date || isNaN(Date.parse(transaction_date))) {
        errors.push(`Transacción ${index}: Fecha de transacción inválida.`);
    }

    return errors;
};

// Handle S3 event
const handleS3Event = async (event) => {
    const s3Event = event.Records[0].s3;
    const bucketName = s3Event.bucket.name;
    const objectKey = decodeURIComponent(s3Event.object.key.replace(/\+/g, " "));

    const s3Object = await s3.getObject({ Bucket: bucketName, Key: objectKey }).promise();
    const transactions = JSON.parse(s3Object.Body.toString());

    const errors = [];
    const validTransactions = [];

    transactions.forEach((transaction, index) => {
        const transactionErrors = validateTransaction(transaction, index);
        if (transactionErrors.length === 0) {
            validTransactions.push(transaction);
        } else {
            errors.push(...transactionErrors);
        }
    });

    return {
        statusCode: 200,
        headers: corsHeaders,
        body: JSON.stringify({
            message: errors.length > 0 ? "Errores en algunas transacciones." : "Todas las transacciones son válidas.",
            errors,
            validTransactions
        })
    };
};

// Handle OPTIONS request for CORS
const handleOptionsRequest = () => {
    return {
        statusCode: 200,
        headers: corsHeaders,
        body: ''
    };
};

// Handle API Gateway event
const handleApiEvent = async (event) => {
    // Handle OPTIONS requests
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({})
        };
    }

    try {
        const body = JSON.parse(event.body || '{}');
        const errors = validateTransaction(body);

        if (errors.length > 0) {
            return {
                statusCode: 400,
                headers: corsHeaders,
                body: JSON.stringify({
                    message: "Transacción inválida",
                    errors
                })
            };
        }

        return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({
                message: "Transacción válida",
                transaction: body
            })
        };
    } catch (error) {
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({
                message: "Error interno del servidor"
            })
        };
    }
};

// Main handler
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event));
    
    try {
        // Check if this is an S3 event
        if (event.Records && event.Records[0].s3) {
            return await handleS3Event(event);
        }
        
        // Otherwise, treat it as an API Gateway event
        return await handleApiEvent(event);
    } catch (error) {
        console.error("Error:", error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({
                message: "Error interno del servidor",
                error: error.message
            })
        };
    }
};