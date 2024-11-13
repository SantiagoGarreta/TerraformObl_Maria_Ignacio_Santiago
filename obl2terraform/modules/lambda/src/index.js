// modules/lambda/src/index.js
exports.handler = async (event) => {
    // CORS headers
    const headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "OPTIONS,POST"
    };
    
    // Handle OPTIONS request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: headers,
            body: JSON.stringify({ message: "OK" })
        };
    }
    
    try {
        console.log('Event:', JSON.stringify(event));
        let transactionData;
        
        // Parse the body if it exists
        if (event.body) {
            try {
                transactionData = JSON.parse(event.body);
            } catch (e) {
                console.error('Error parsing body:', e);
                return {
                    statusCode: 400,
                    headers: headers,
                    body: JSON.stringify({
                        message: "Invalid request body - must be valid JSON",
                        error: e.message
                    })
                };
            }
        }

        // Generate transaction ID if not provided
        if (!transactionData.transaction_id) {
            transactionData.transaction_id = 'TRX-' + Date.now();
        }

        // Add timestamp if not provided
        if (!transactionData.transaction_date) {
            transactionData.transaction_date = new Date().toISOString();
        }

        // Return success response
        return {
            statusCode: 200,
            headers: headers,
            body: JSON.stringify({
                message: "Transaction processed successfully",
                data: transactionData
            })
        };
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers: headers,
            body: JSON.stringify({
                message: "Error processing transaction",
                error: error.message
            })
        };
    }
};