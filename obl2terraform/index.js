const acceptedCurrencies = [
    "USD", "CAD", "EUR", "GBP", "UYU", "ARS", "BRL", "CLP", "COP", "PEN", "PYG", "MXN"
];

const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    try {
        const s3Event = event.Records[0].s3;
        const bucketName = s3Event.bucket.name;
        const objectKey = decodeURIComponent(s3Event.object.key.replace(/\+/g, " "));

        const s3Object = await s3.getObject({ Bucket: bucketName, Key: objectKey }).promise();
        const transactions = JSON.parse(s3Object.Body.toString());

        const errors = [];
        const validTransactions = [];

        transactions.forEach((transaction, index) => {
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

            if (errors.length === 0) {
                validTransactions.push(transaction);
            }
        });

        if (errors.length > 0) {
            console.error("Errores encontrados en las transacciones:", errors);
        } else {
            console.log("Todas las transacciones son válidas:", validTransactions);
        }

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: errors.length > 0 ? "Errores en algunas transacciones." : "Todas las transacciones son válidas.",
                errors,
                validTransactions
            })
        };

    } catch (error) {
        console.error("Error procesando el archivo JSON:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: "Error interno al procesar el archivo." })
        };
    }
};
