#!/usr/bin/env bash
set -e

PROJECT="$HOME/XRP1-RED/XRP-SCAN-"
cd "$PROJECT"

echo "======================================"
echo " XRP-RED-scan Automatic Setup"
echo "======================================"

echo "[1/8] Checking project..."
if [ ! -f "app.py" ] && [ ! -f "backend/app.py" ]; then
    echo "ERROR: Flask app not found."
    exit 1
fi

echo "[2/8] Setting Git identity..."
git config --global user.name "johnsteven1"

if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
    echo "Enter the email associated with your GitHub account:"
    read -r GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi

echo "[3/8] Updating GitHub remote..."
git remote set-url origin https://github.com/johnsteven1/XRP-RED-scan.git

echo "[4/8] Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    python3 -m pip install -r requirements.txt
elif [ -f "backend/requirements.txt" ]; then
    python3 -m pip install -r backend/requirements.txt
fi

echo "[5/8] Creating Render configuration..."

cat > render.yaml <<'RENDER'
services:
  - type: web
    name: xrp-red-scan-backend
    runtime: python
    rootDir: .
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn --bind 0.0.0.0:$PORT --workers 2 --threads 2 --timeout 300 app:app
    plan: free
RENDER

echo "[6/8] Checking frontend API configuration..."

API_FILE="frontend/js/app.js"

if [ -f "$API_FILE" ]; then
    echo "Current API setting:"
    grep -n "API_BASE" "$API_FILE" || true

    echo
    echo "Enter your Render BACKEND URL."
    echo "Example: https://xrp-red-scan-backend.onrender.com"
    echo "Leave blank if you haven't deployed the backend yet."
    read -r BACKEND_URL

    if [ -n "$BACKEND_URL" ]; then
        BACKEND_URL="${BACKEND_URL%/}"
        sed -i "s|const API_BASE = .*;|const API_BASE = '${BACKEND_URL}/api';|" "$API_FILE"
        echo "Frontend API updated to:"
        grep -n "API_BASE" "$API_FILE"
    else
        echo "Backend URL skipped."
    fi
fi

echo "[7/8] Adding project files to Git..."

git add .

if git diff --cached --quiet; then
    echo "No new changes to commit."
else
    git commit -m "Prepare XRP-RED-scan for Render deployment"
fi

echo "[8/8] Pushing to GitHub..."

git branch -M main
git push -u origin main

echo
echo "======================================"
echo " SETUP COMPLETE"
echo "======================================"
echo
echo "GitHub:"
echo "https://github.com/johnsteven1/XRP-RED-scan"
echo
echo "Next:"
echo "Deploy the xrp-red-scan-backend service on Render."
echo
