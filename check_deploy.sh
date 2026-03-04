#!/bin/bash
# check_deploy.sh - Check active environment and HTTP status of blue/green websites

DEPLOY_FILE="deployment.json"

ACTIVE=$(jq -r '.active_environment' "$DEPLOY_FILE")
echo "Active environment: $ACTIVE"

BLUE_URL="http://deploy-lab-blue.s3-website-us-east-1.amazonaws.com"
GREEN_URL="http://deploy-lab-green.s3-website-us-east-1.amazonaws.com"


echo "Checking HTTP status..."
BLUE_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" "$BLUE_URL")
GREEN_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" "$GREEN_URL")

echo "Blue URL: $BLUE_URL -> HTTP $BLUE_STATUS"
echo "Green URL: $GREEN_URL -> HTTP $GREEN_STATUS"

if [ "$ACTIVE" == "blue" ]; then
    echo "Blue is active. Green is ready for next deploy."
else
    echo "Green is active. Blue is ready for next deploy."
fi
