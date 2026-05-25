#!/bin/bash

###############################################################################
# Setup Automation Script
# Purpose: Install automated cleanup cron jobs
# Usage: sudo ./setup-automation.sh
###############################################################################

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root: sudo ./setup-automation.sh"
    exit 1
fi

echo "🤖 Setting up automated cleanup jobs"
echo "====================================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make cleanup scripts executable
echo "📝 Making cleanup scripts executable..."
chmod +x "$SCRIPT_DIR/cleanup-docker.sh"
chmod +x "$SCRIPT_DIR/cleanup-system.sh"
chmod +x "$SCRIPT_DIR/monitor-disk.sh"

# Create cron jobs
echo "⏰ Setting up cron jobs..."

# Backup existing crontab
crontab -l > /tmp/crontab_backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create new crontab entries
(crontab -l 2>/dev/null || true; cat <<EOF

# Automated Cleanup Jobs for Docker & System
# Added by setup-automation.sh on $(date)

# Docker cleanup - Every Sunday at 2 AM
0 2 * * 0 $SCRIPT_DIR/cleanup-docker.sh >> /var/log/docker-cleanup.log 2>&1

# System cleanup - First day of every month at 3 AM
0 3 1 * * $SCRIPT_DIR/cleanup-system.sh >> /var/log/system-cleanup.log 2>&1

# Disk monitoring - Every 6 hours
0 */6 * * * $SCRIPT_DIR/monitor-disk.sh >> /var/log/disk-monitor.log 2>&1

EOF
) | crontab -

echo "✅ Cron jobs installed successfully!"
echo ""
echo "📋 Scheduled jobs:"
echo "   - Docker cleanup: Every Sunday at 2 AM"
echo "   - System cleanup: First day of every month at 3 AM"
echo "   - Disk monitoring: Every 6 hours"
echo ""
echo "📝 Logs will be saved to:"
echo "   - /var/log/docker-cleanup.log"
echo "   - /var/log/system-cleanup.log"
echo "   - /var/log/disk-monitor.log"
echo ""
echo "🔍 To view current cron jobs: crontab -l"
echo "🗑️  To remove automation: crontab -e (then delete the lines)"
echo ""
echo "✅ Setup complete!"

# Made with Bob
