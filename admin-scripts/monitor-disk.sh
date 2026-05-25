#!/bin/bash

###############################################################################
# Disk Space Monitoring Script
# Purpose: Monitor disk usage and auto-cleanup if threshold exceeded
# Usage: ./monitor-disk.sh
###############################################################################

set -e

# Configuration
THRESHOLD=80  # Alert if disk usage exceeds this percentage
CRITICAL=90   # Auto-cleanup if disk usage exceeds this percentage

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Get current disk usage percentage
USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

echo "📊 Disk Space Monitor - $(date)"
echo "================================"
echo "Current disk usage: ${USAGE}%"
echo ""

# Show disk usage
df -h | grep -E "Filesystem|/dev/root"
echo ""

# Check if usage exceeds critical threshold
if [ $USAGE -gt $CRITICAL ]; then
    echo -e "${RED}🚨 CRITICAL: Disk usage at ${USAGE}%!${NC}"
    echo "Running automatic cleanup..."
    
    # Run Docker cleanup
    echo "🧹 Cleaning Docker resources..."
    docker system prune -f --filter "until=72h" || true
    docker image prune -a -f --filter "until=168h" || true
    
    # Clean logs
    echo "🧹 Cleaning old logs..."
    sudo journalctl --vacuum-time=2d || true
    
    # Show new usage
    NEW_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo ""
    echo "Disk usage after cleanup: ${NEW_USAGE}%"
    
    if [ $NEW_USAGE -gt $CRITICAL ]; then
        echo -e "${RED}⚠️  WARNING: Still above critical threshold!${NC}"
        echo "Manual intervention required. Consider:"
        echo "  1. Resizing EBS volume"
        echo "  2. Removing old Jenkins builds"
        echo "  3. Checking for large files: sudo du -h --max-depth=1 / | sort -hr | head -10"
    else
        echo -e "${GREEN}✅ Cleanup successful!${NC}"
    fi
    
elif [ $USAGE -gt $THRESHOLD ]; then
    echo -e "${YELLOW}⚠️  WARNING: Disk usage at ${USAGE}%${NC}"
    echo "Approaching threshold. Consider running cleanup soon."
    echo "Run: ./cleanup-docker.sh"
    
else
    echo -e "${GREEN}✅ Disk usage is healthy (${USAGE}%)${NC}"
fi

# Show Docker disk usage
echo ""
echo "🐳 Docker disk usage:"
docker system df 2>/dev/null || echo "Docker not running or not accessible"

echo ""
echo "💡 Tip: Run './cleanup-docker.sh' to free up space"

# Made with Bob
