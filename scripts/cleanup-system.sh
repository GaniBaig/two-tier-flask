#!/bin/bash

###############################################################################
# System Cleanup Script for EC2
# Purpose: Clean system logs, cache, and temporary files
# Usage: sudo ./cleanup-system.sh
###############################################################################

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root: sudo ./cleanup-system.sh"
    exit 1
fi

echo "🧹 System Cleanup Script Started"
echo "================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Show initial disk usage
echo "📊 Before cleanup:"
df -h | grep -E "Filesystem|/dev/root"
echo ""

# Step 1: Clean APT cache
echo "🗑️  Step 1: Cleaning APT cache..."
apt-get clean
apt-get autoclean
apt-get autoremove -y
echo -e "${GREEN}✅ APT cache cleaned${NC}"

# Step 2: Clean journal logs (keep last 3 days)
echo "🗑️  Step 2: Cleaning journal logs (keeping last 3 days)..."
journalctl --vacuum-time=3d
echo -e "${GREEN}✅ Journal logs cleaned${NC}"

# Step 3: Clean old log files
echo "🗑️  Step 3: Cleaning old log files..."
find /var/log -type f -name "*.log" -mtime +7 -exec truncate -s 0 {} \;
find /var/log -type f -name "*.gz" -delete
find /var/log -type f -name "*.1" -delete
find /var/log -type f -name "*.old" -delete
echo -e "${GREEN}✅ Old log files cleaned${NC}"

# Step 4: Clean temporary files
echo "🗑️  Step 4: Cleaning temporary files..."
rm -rf /tmp/*
rm -rf /var/tmp/*
echo -e "${GREEN}✅ Temporary files cleaned${NC}"

# Step 5: Clean snap old versions
echo "🗑️  Step 5: Cleaning old snap versions..."
snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
    snap remove "$snapname" --revision="$revision" 2>/dev/null || true
done
echo -e "${GREEN}✅ Old snap versions cleaned${NC}"

# Step 6: Clean thumbnail cache
echo "🗑️  Step 6: Cleaning thumbnail cache..."
rm -rf /home/*/.cache/thumbnails/* 2>/dev/null || true
echo -e "${GREEN}✅ Thumbnail cache cleaned${NC}"

# Show final disk usage
echo ""
echo "📊 After cleanup:"
df -h | grep -E "Filesystem|/dev/root"
echo ""

echo -e "${GREEN}✅ System cleanup completed successfully!${NC}"
echo ""
echo "💡 Tip: Run this monthly for best results"

# Made with Bob
