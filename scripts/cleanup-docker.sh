#!/bin/bash

###############################################################################
# Docker Cleanup Script for EC2
# Purpose: Automatically clean Docker resources to free up disk space
# Usage: ./cleanup-docker.sh [--aggressive]
###############################################################################

set -e

echo "🧹 Docker Cleanup Script Started"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running with aggressive flag
AGGRESSIVE=false
if [ "$1" == "--aggressive" ]; then
    AGGRESSIVE=true
    echo -e "${YELLOW}⚠️  Running in AGGRESSIVE mode${NC}"
fi

# Function to show disk usage
show_disk_usage() {
    echo ""
    echo "📊 Current Disk Usage:"
    df -h | grep -E "Filesystem|/dev/root"
    echo ""
    echo "🐳 Docker Disk Usage:"
    docker system df
    echo ""
}

# Show initial disk usage
echo "Before cleanup:"
show_disk_usage

# Step 1: Remove stopped containers
echo "🗑️  Step 1: Removing stopped containers..."
STOPPED=$(docker container prune -f 2>&1 | grep "Total reclaimed space" || echo "0B")
echo "   Freed: $STOPPED"

# Step 2: Remove dangling images
echo "🗑️  Step 2: Removing dangling images..."
DANGLING=$(docker image prune -f 2>&1 | grep "Total reclaimed space" || echo "0B")
echo "   Freed: $DANGLING"

# Step 3: Remove unused networks
echo "🗑️  Step 3: Removing unused networks..."
docker network prune -f > /dev/null 2>&1 || true

# Step 4: Remove build cache
echo "🗑️  Step 4: Removing build cache..."
BUILD_CACHE=$(docker builder prune -f 2>&1 | grep "Total" || echo "0B")
echo "   Freed: $BUILD_CACHE"

if [ "$AGGRESSIVE" = true ]; then
    echo ""
    echo -e "${YELLOW}⚠️  AGGRESSIVE CLEANUP MODE${NC}"
    
    # Step 5: Remove all unused images (not just dangling)
    echo "🗑️  Step 5: Removing ALL unused images..."
    UNUSED=$(docker image prune -a -f 2>&1 | grep "Total reclaimed space" || echo "0B")
    echo "   Freed: $UNUSED"
    
    # Step 6: Remove unused volumes
    echo "🗑️  Step 6: Removing unused volumes..."
    VOLUMES=$(docker volume prune -f 2>&1 | grep "Total reclaimed space" || echo "0B")
    echo "   Freed: $VOLUMES"
fi

# Show final disk usage
echo ""
echo "After cleanup:"
show_disk_usage

# Calculate and show space freed
echo -e "${GREEN}✅ Cleanup completed successfully!${NC}"
echo ""
echo "💡 Tips:"
echo "   - Run this script weekly: sudo crontab -e"
echo "   - Add: 0 2 * * 0 /path/to/cleanup-docker.sh"
echo "   - For aggressive cleanup: ./cleanup-docker.sh --aggressive"
echo ""

# Made with Bob
