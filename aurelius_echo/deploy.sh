#!/bin/bash
set -e

echo "=== The Stoic Indian Deployment ==="
echo ""

# Variables
DEPLOY_DIR="/var/www/aurelius"
SOURCE_DIR="$HOME/aurelius-echo"

# Verify we're in the source directory
if [ ! -f "$SOURCE_DIR/package.json" ]; then
    echo "Error: Source directory not found at $SOURCE_DIR"
    exit 1
fi

# Verify .env.local exists
if [ ! -f "$SOURCE_DIR/.env.local" ]; then
    echo "Error: .env.local not found!"
    exit 1
fi

echo "Step 1: Creating deployment directory..."
sudo mkdir -p "$DEPLOY_DIR"
sudo chown -R $USER:$USER "$DEPLOY_DIR"

echo "Step 2: Copying project files..."
cd "$SOURCE_DIR"
rsync -av \
    --exclude 'node_modules' \
    --exclude 'dist' \
    --exclude '.git' \
    --exclude '*.sh' \
    --exclude 'ai_studio_code*.sh' \
    ./ "$DEPLOY_DIR/"

echo "Step 3: Setting up environment file..."
# Convert GEMINI_API_KEY to API_KEY for production
cd "$DEPLOY_DIR"
sed 's/GEMINI_API_KEY=/API_KEY=/' "$SOURCE_DIR/.env.local" > .env
echo "Environment file created (.env)"

echo "Step 4: Installing dependencies..."
npm install

echo "Step 5: Building frontend..."
npm run build

echo "Step 6: Managing PM2 process..."
# Stop and delete existing process if it exists
if pm2 list | grep -q "aurelius"; then
    echo "Stopping existing PM2 process..."
    pm2 stop aurelius
    pm2 delete aurelius
fi

# Start the server
echo "Starting server with PM2..."
pm2 start npm --name "aurelius" -- start
pm2 save

echo ""
echo "=== Deployment Complete! ==="
echo "Application is running on port 3333"
echo ""
echo "Useful commands:"
echo "  pm2 logs aurelius   - View logs"
echo "  pm2 restart aurelius - Restart server"
echo "  pm2 status          - Check status"
echo ""
