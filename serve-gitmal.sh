#!/bin/bash
# ./serve-gitmal.sh

# Script to refresh gitmal visualization, host it locally, and open in browser

# Ensure gitmal is in PATH
export PATH="$HOME/go/bin:$PATH"

set -e

# Configuration
OUTPUT_DIR="output"
PORT=8000
REPO_PATH="."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Refreshing gitmal visualization...${NC}"
# Include all branches and ensure all files are processed
gitmal --output "$OUTPUT_DIR" --branches ".*" --name "Agentic Design Patterns" "$REPO_PATH"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}⚠️  Warning: Output directory '$OUTPUT_DIR' was not created${NC}"
    exit 1
fi

# Check if index.html exists
if [ ! -f "$OUTPUT_DIR/index.html" ]; then
    echo -e "${YELLOW}⚠️  Warning: index.html not found in output directory${NC}"
    # Try to find any HTML file
    HTML_FILE=$(find "$OUTPUT_DIR" -name "*.html" -type f | head -1)
    if [ -z "$HTML_FILE" ]; then
        echo -e "${YELLOW}❌ No HTML files found in output directory${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Found HTML file: $HTML_FILE${NC}"
fi

echo -e "${GREEN}✓ Gitmal visualization generated successfully${NC}"
echo -e "${BLUE}🌐 Starting local web server on port $PORT...${NC}"

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping web server...${NC}"
    kill $SERVER_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Get the script directory to find gitmal_server.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Start the custom web server in the background (better MIME type handling)
# We cd into OUTPUT_DIR first, then serve from current directory
cd "$OUTPUT_DIR"
python3 "$SCRIPT_DIR/gitmal_server.py" "$PORT" "." > /dev/null 2>&1 &
SERVER_PID=$!

# Wait a moment for server to start
sleep 1

# Check if server is running
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "${YELLOW}❌ Failed to start web server${NC}"
    exit 1
fi

URL="http://localhost:$PORT"
echo -e "${GREEN}✓ Server running at ${URL}${NC}"
echo -e "${BLUE}🌍 Opening browser...${NC}"

# Open browser (works on macOS)
open "$URL"

echo -e "${GREEN}✓ Browser opened!${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"

# Wait for the server process
wait $SERVER_PID
