#!/bin/bash

# Create the necessary directories
mkdir -p modules/s3_staticWebSite/static/banking

# Copy the transactions.html template if it doesn't exist
if [ ! -f modules/s3_staticWebSite/static/banking/transactions.html ]; then
    cp templates/transactions.html modules/s3_staticWebSite/static/banking/transactions.html
fi

# Build Angular app
cd angular-app
npm install
ng build --configuration=production
cd ..

echo "Frontend files prepared successfully!"