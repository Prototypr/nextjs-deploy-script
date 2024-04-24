#!/bin/bash

#both app folders start with 'next-app'
LIVE_DIR_PATH=/var/www/html/next-app

#add the suffixes to the app folders
BLUE_DIR=$LIVE_DIR_PATH-blue
GREEN_DIR=$LIVE_DIR_PATH-green

# set up variables to store the current live and deploying to directories
CURRENT_LIVE_NAME=false
CURRENT_LIVE_DIR=false

DEPLOYING_TO_NAME=false
DEPLOYING_TO_DIR=false

# this checks if the green and blue apps are running
GREEN_ONLINE=$(pm2 jlist | jq -r '.[] | select(.name == "green") | .name, .pm2_env.status' | tr -d '\n\r')
BLUE_ONLINE=$(pm2 jlist | jq -r '.[] | select(.name == "blue") | .name, .pm2_env.status' | tr -d '\n\r')

# if green is running, set the current live to green and 'deploying to' is blue
if [ "$GREEN_ONLINE" == "greenonline" ]; then
    echo "Green is running"
    CURRENT_LIVE_NAME="green"
    CURRENT_LIVE_DIR=$GREEN_DIR
    
    DEPLOYING_TO_NAME="blue"
    DEPLOYING_TO_DIR=$BLUE_DIR
fi

# if blue is running, set the current live to blue and 'deploying to' is green
if [ "$BLUE_ONLINE" == "blueonline" ]; then
    echo "Blue is running"
    CURRENT_LIVE_NAME="blue"
    CURRENT_LIVE_DIR=$BLUE_DIR
    
    DEPLOYING_TO_NAME="green"
    DEPLOYING_TO_DIR=$GREEN_DIR
fi

# if both green and blue are running, set 'deploying to' to blue
if [ "$GREEN_ONLINE" == "greenonline" ] && [ "$BLUE_ONLINE" == "blueonline" ]; then
    echo "Both blue and green are running"
    DEPLOYING_TO_DIR=$BLUE_DIR
fi

# display the current live and deploying to directories
echo "Current live: $CURRENT_LIVE_NAME"
echo "Deploying to: $DEPLOYING_TO_NAME"

echo "Current live dir: $CURRENT_LIVE_DIR"
echo "Deploying to dir: $DEPLOYING_TO_DIR"

# Navigate to the deploying to directory
cd $DEPLOYING_TO_DIR || { echo 'Could not access deployment directory.' ; exit 1; }

# use the correct node version
# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

nvm use 18.17.0 || { echo 'Could not switch to node version 18.17.0' ; exit 1; }

# load the .env file
source .env.local || { echo 'The ENV file does not exist' ; exit 1; }


# Pull the latest changes
# clear any changes to avoid conflicts (usually permission based)
git reset --hard || { echo 'Git reset command failed' ; exit 1; }
git pull -f origin main || { echo 'Git pull command failed' ; exit 1; }

# install the dependencies
npm install --legacy-peer-deps || { echo 'npm install failed' ; exit 1; }
# Build the project
npm run build || { echo 'Build failed' ; exit 1; }

# Restart the pm2 process
pm2 restart $DEPLOYING_TO_NAME || { echo 'pm2 restart failed' ; exit 1; }

# add a delay to allow the server to start
sleep 5

# check if the server is running
DEPLOYMENT_ONLINE=$(pm2 jlist | jq -r '.[] | select(.name == "$DEPLOYING_TO_NAME") | .name, .pm2_env.status' | tr -d '\n\r')

if [ "$DEPLOYMENT_ONLINE" == "$DEPLOYING_TO_NAMEonline" ]; then
    echo "Deployment successful"
else
    echo "Deployment failed"
    exit 1
fi

# stop the live one which is out of date
pm2 stop $CURRENT_LIVE_NAME;
