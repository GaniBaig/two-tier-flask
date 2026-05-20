# 🔍 Debugging "Port Already in Use" Error

## 🚨 Your Error

```
Error: unable to start container: "listen tcp :5000: bind: address already in use"
```

**What this means:** Something is already running on port 5000 on your Mac, so the Flask container can't use it.

---

## 🔎 Step 1: Find What's Using Port 5000

### Method 1: Using `lsof` (Recommended for Mac)

```bash
# Check what's using port 5000
lsof -i :5000
```

**Example output:**
```
COMMAND   PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
python    1234  mirza  3u   IPv4 0x1234567890      0t0  TCP *:5000 (LISTEN)
```

**What this tells you:**
- `COMMAND`: The program name (e.g., python, node, docker)
- `PID`: Process ID (e.g., 1234)
- `USER`: Who's running it (e.g., mirza)
- `NAME`: The port (*:5000 means listening on all interfaces)

### Method 2: Using `netstat`

```bash
# Check port 5000
netstat -anv | grep 5000
```

### Method 3: Using `lsof` with more details

```bash
# Get detailed info about port 5000
sudo lsof -i :5000 -P
```

---

## 🛑 Step 2: Stop the Process Using Port 5000

### Option A: Kill by Process ID (PID)

```bash
# First, find the PID
lsof -i :5000

# Then kill it (replace 1234 with actual PID)
kill -9 1234

# Verify it's gone
lsof -i :5000
```

### Option B: Kill by Process Name

```bash
# If it's a Python process
pkill -9 python

# If it's a Node.js process
pkill -9 node

# If it's another Flask app
pkill -9 flask
```

### Option C: Kill All Python Processes (Use with Caution!)

```bash
# This will kill ALL Python processes
killall python
killall python3
```

---

## 🔍 Step 3: Check for Other Common Culprits

### Check if it's a Previous Podman Container

```bash
# List all running containers
podman ps

# List all containers (including stopped)
podman ps -a

# Stop all containers
podman stop $(podman ps -aq)

# Remove all containers
podman rm $(podman ps -aq)
```

### Check if it's AirPlay Receiver (macOS Monterey+)

**macOS uses port 5000 for AirPlay Receiver by default!**

**To disable AirPlay Receiver:**

1. Open **System Settings** (or System Preferences)
2. Go to **General** → **AirDrop & Handoff** (or **Sharing**)
3. Turn OFF **AirPlay Receiver**

**Or use command line:**
```bash
# Check if AirPlay is using port 5000
sudo lsof -i :5000 | grep ControlCe

# If you see ControlCenter, that's AirPlay
```

### Check if it's a Previous Docker/Podman Instance

```bash
# Check Docker containers (if you have Docker installed)
docker ps
docker stop $(docker ps -aq)

# Check Podman containers
podman ps
podman stop $(podman ps -aq)
```

---

## ✅ Step 4: Verify Port is Free

```bash
# Check if port 5000 is now free
lsof -i :5000

# Should return nothing if port is free
```

**If the command returns nothing, the port is free!** ✅

---

## 🚀 Step 5: Restart Your Application

```bash
# Navigate to project directory
cd /Users/mirzaabdulganibaig/Documents/devops/two-tier/DevOps-Project-Two-Tier-Flask-App

# Start the application
podman-compose up -d

# Check if it's running
podman-compose ps
```

---

## 🔄 Alternative Solution: Use a Different Port

If you can't free port 5000 (or don't want to), you can change the port:

### Option 1: Modify docker-compose.yml

```bash
# Edit docker-compose.yml
nano docker-compose.yml
```

**Change this:**
```yaml
flask-app:
  ports:
    - "5000:5000"  # Change first 5000 to something else
```

**To this:**
```yaml
flask-app:
  ports:
    - "5001:5000"  # Now accessible at http://localhost:5001
```

**Then restart:**
```bash
podman-compose down
podman-compose up -d

# Access at http://localhost:5001
```

### Option 2: Use Environment Variable

```bash
# Set different port
export FLASK_PORT=5001

# Modify docker-compose.yml to use variable
# ports:
#   - "${FLASK_PORT:-5000}:5000"
```

---

## 🎯 Complete Debugging Workflow

Here's the complete step-by-step process:

```bash
# 1. Check what's using port 5000
echo "=== Checking port 5000 ==="
lsof -i :5000

# 2. If something is found, note the PID
# Example output: python 1234 mirza ...

# 3. Kill the process (replace 1234 with actual PID)
echo "=== Killing process ==="
kill -9 1234

# 4. Verify port is free
echo "=== Verifying port is free ==="
lsof -i :5000
# Should return nothing

# 5. Stop any existing containers
echo "=== Stopping existing containers ==="
podman-compose down

# 6. Start fresh
echo "=== Starting application ==="
podman-compose up -d

# 7. Check status
echo "=== Checking status ==="
podman-compose ps

# 8. Test the application
echo "=== Testing application ==="
curl http://localhost:5000/health
```

---

## 📋 Quick Reference Commands

### Find What's Using a Port

```bash
# Port 5000
lsof -i :5000

# Port 3306 (MySQL)
lsof -i :3306

# Any port (replace XXXX)
lsof -i :XXXX

# With sudo for more details
sudo lsof -i :5000
```

### Kill Process by PID

```bash
# Graceful kill
kill PID

# Force kill
kill -9 PID

# Kill multiple PIDs
kill -9 1234 5678 9012
```

### Kill Process by Name

```bash
# Kill all Python processes
pkill python

# Force kill all Python processes
pkill -9 python

# Kill specific process
pkill -9 flask
```

### Check All Listening Ports

```bash
# See all ports in use
lsof -i -P | grep LISTEN

# See all ports with process names
netstat -anv | grep LISTEN
```

---

## 🐛 Common Scenarios & Solutions

### Scenario 1: AirPlay Receiver (Most Common on Mac)

**Problem:** macOS Monterey+ uses port 5000 for AirPlay

**Solution:**
```bash
# Check if it's AirPlay
sudo lsof -i :5000 | grep ControlCe

# Disable AirPlay Receiver in System Settings
# Or use a different port (5001, 8000, etc.)
```

### Scenario 2: Previous Flask App Still Running

**Problem:** You ran Flask directly before, and it's still running

**Solution:**
```bash
# Find and kill Python processes
ps aux | grep python
pkill -9 python

# Or find specific Flask process
ps aux | grep flask
kill -9 <PID>
```

### Scenario 3: Previous Container Still Running

**Problem:** Old container from previous run

**Solution:**
```bash
# Stop all containers
podman stop $(podman ps -aq)

# Remove all containers
podman rm $(podman ps -aq)

# Start fresh
podman-compose up -d
```

### Scenario 4: Port Forwarding from Podman Machine

**Problem:** Podman machine has port forwarding conflict

**Solution:**
```bash
# Restart Podman machine
podman machine stop
podman machine start

# Or recreate the machine
podman machine rm podman-machine-default
podman machine init
podman machine start
```

### Scenario 5: Multiple Instances of Same App

**Problem:** You started the app multiple times

**Solution:**
```bash
# Find all instances
ps aux | grep "app.py"

# Kill all Python processes
killall python3

# Clean up containers
podman-compose down
podman system prune -f
```

---

## 🔧 Preventive Measures

### 1. Always Stop Before Starting

```bash
# Good practice
podman-compose down
podman-compose up -d

# Not just
podman-compose up -d
```

### 2. Use Unique Ports for Different Projects

```yaml
# Project 1: Port 5000
ports:
  - "5000:5000"

# Project 2: Port 5001
ports:
  - "5001:5000"

# Project 3: Port 5002
ports:
  - "5002:5000"
```

### 3. Check Ports Before Starting

```bash
# Create a pre-start script
#!/bin/bash
if lsof -i :5000 > /dev/null; then
    echo "Port 5000 is in use!"
    lsof -i :5000
    exit 1
else
    echo "Port 5000 is free, starting app..."
    podman-compose up -d
fi
```

### 4. Use Docker/Podman Compose Properly

```bash
# Always use compose commands
podman-compose up -d    # Start
podman-compose down     # Stop
podman-compose restart  # Restart

# Don't mix with manual podman commands
```

---

## 📊 Diagnostic Script

Save this as `check-ports.sh`:

```bash
#!/bin/bash

echo "==================================="
echo "Port Conflict Diagnostic Tool"
echo "==================================="
echo ""

# Check port 5000
echo "Checking port 5000 (Flask)..."
if lsof -i :5000 > /dev/null 2>&1; then
    echo "❌ Port 5000 is IN USE:"
    lsof -i :5000
else
    echo "✅ Port 5000 is FREE"
fi
echo ""

# Check port 3306
echo "Checking port 3306 (MySQL)..."
if lsof -i :3306 > /dev/null 2>&1; then
    echo "❌ Port 3306 is IN USE:"
    lsof -i :3306
else
    echo "✅ Port 3306 is FREE"
fi
echo ""

# Check Podman containers
echo "Checking Podman containers..."
if podman ps -q > /dev/null 2>&1; then
    CONTAINERS=$(podman ps -q | wc -l)
    if [ $CONTAINERS -gt 0 ]; then
        echo "⚠️  Found $CONTAINERS running container(s):"
        podman ps
    else
        echo "✅ No running containers"
    fi
else
    echo "⚠️  Podman not running or not installed"
fi
echo ""

# Check Podman machine
echo "Checking Podman machine..."
if podman machine list > /dev/null 2>&1; then
    podman machine list
else
    echo "⚠️  Podman machine not initialized"
fi
echo ""

echo "==================================="
echo "Diagnostic complete!"
echo "==================================="
```

**Usage:**
```bash
chmod +x check-ports.sh
./check-ports.sh
```

---

## 🎯 Your Specific Case - Action Plan

Based on your error, here's what you should do **right now**:

```bash
# 1. Check what's using port 5000
lsof -i :5000

# 2. You'll likely see one of these:
#    - ControlCenter (AirPlay) - Disable in System Settings
#    - python/python3 - Kill with: pkill -9 python
#    - Previous container - Stop with: podman stop $(podman ps -aq)

# 3. If it's AirPlay (most likely on Mac):
#    Go to System Settings → General → AirDrop & Handoff
#    Turn OFF "AirPlay Receiver"

# 4. Verify port is free
lsof -i :5000
# Should return nothing

# 5. Clean up any existing containers
podman-compose down
podman system prune -f

# 6. Start fresh
podman-compose up -d

# 7. Verify it's working
podman-compose ps
curl http://localhost:5000/health
```

---

## 💡 Pro Tips

1. **Always check ports before starting**: `lsof -i :5000`
2. **Use `podman-compose down` before `up`**: Ensures clean state
3. **Disable AirPlay Receiver on Mac**: It uses port 5000 by default
4. **Use different ports for different projects**: Avoid conflicts
5. **Keep a port reference**: Document which ports your projects use

---

## 🆘 Still Having Issues?

If port 5000 is still in use after trying everything:

### Nuclear Option: Use a Different Port

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change:
# ports:
#   - "5000:5000"
# To:
# ports:
#   - "8080:5000"

# Then start
podman-compose up -d

# Access at http://localhost:8080
```

### Check System Services

```bash
# Check what services are running
launchctl list | grep -i port

# Check system logs
log show --predicate 'eventMessage contains "5000"' --last 1h
```

---

## ✅ Success Checklist

- [ ] Identified what's using port 5000
- [ ] Stopped/killed the process
- [ ] Verified port is free (`lsof -i :5000` returns nothing)
- [ ] Cleaned up old containers (`podman-compose down`)
- [ ] Started application (`podman-compose up -d`)
- [ ] Verified containers are running (`podman-compose ps`)
- [ ] Tested application (`curl http://localhost:5000/health`)
- [ ] Accessed in browser (`http://localhost:5000`)

---

**Good luck! You've got this! 🚀**