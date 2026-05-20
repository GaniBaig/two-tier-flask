# 🚀 Local Setup Guide - Flask Two-Tier App on Mac with Podman

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install Podman on Mac](#install-podman-on-mac)
3. [Setup Project Locally](#setup-project-locally)
4. [Run Application with Podman](#run-application-with-podman)
5. [Verify Application](#verify-application)
6. [Troubleshooting](#troubleshooting)
7. [Next Steps - AWS Deployment](#next-steps)

---

## ✅ Prerequisites

Before starting, make sure you have:

- macOS (you're on a Mac)
- Homebrew installed
- Terminal access
- Internet connection
- Basic command line knowledge

---

## 🔧 Step 1: Install Podman on Mac

Podman is a Docker alternative that doesn't require root privileges and is more secure.

### 1.1 Install Homebrew (if not already installed)

```bash
# Check if Homebrew is installed
brew --version

# If not installed, install it:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1.2 Install Podman

```bash
# Install Podman
brew install podman

# Verify installation
podman --version
```

**Expected output:**

```
podman version 4.x.x
```

### 1.3 Initialize Podman Machine

Podman on Mac runs in a lightweight VM. You need to initialize it:

```bash
# Initialize the Podman machine
podman machine init

# Start the Podman machine
podman machine start

# Verify it's running
podman machine list
```

**Expected output:**

```
NAME                     VM TYPE     CREATED      LAST UP            CPUS        MEMORY      DISK SIZE
podman-machine-default*  qemu        2 hours ago  Currently running  2           2GiB        100GiB
```

### 1.4 Set up Podman Compose

```bash
# Install podman-compose (Docker Compose equivalent for Podman)
brew install podman-compose

# Verify installation
podman-compose --version
```

---

## 📁 Step 2: Setup Project Locally

### 2.1 Navigate to Project Directory

```bash
# Go to your project directory
cd /Users/mirzaabdulganibaig/Documents/devops/two-tier/DevOps-Project-Two-Tier-Flask-App

# Verify you're in the right directory
pwd
ls -la
```

**You should see:**

```
app.py
docker-compose.yml
Dockerfile
requirement.txt
templates/
```

### 2.2 Review Project Files

Let's understand what we have:

```bash
# View the Flask application
cat app.py

# View the Dockerfile
cat Dockerfile

# View docker-compose configuration
cat docker-compose.yml

# View Python dependencies
cat requirement.txt
```

### 2.3 Create Missing Health Endpoint (Important!)

The docker-compose.yml expects a `/health` endpoint, but it's not in app.py. Let's add it:

```bash
# Create a backup first
cp app.py app.py.backup

# Edit app.py to add health endpoint
nano app.py
```

**Add this code before the `if __name__ == '__main__':` line:**

```python
@app.route('/health')
def health():
    """Health check endpoint for container orchestration"""
    try:
        # Check database connection
        cur = mysql.connection.cursor()
        cur.execute('SELECT 1')
        cur.close()
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 503
```

**Or use this one-liner to add it:**

```bash
# Add health endpoint automatically
cat > /tmp/health_endpoint.py << 'EOF'

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        cur = mysql.connection.cursor()
        cur.execute('SELECT 1')
        cur.close()
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 503

EOF

# Insert before the if __name__ line
sed -i.bak '/if __name__/i\
@app.route('"'"'/health'"'"')\
def health():\
    """Health check endpoint"""\
    try:\
        cur = mysql.connection.cursor()\
        cur.execute('"'"'SELECT 1'"'"')\
        cur.close()\
        return jsonify({'"'"'status'"'"': '"'"'healthy'"'"', '"'"'database'"'"': '"'"'connected'"'"'}), 200\
    except Exception as e:\
        return jsonify({'"'"'status'"'"': '"'"'unhealthy'"'"', '"'"'error'"'"': str(e)}), 503\
' app.py
```

---

## 🐳 Step 3: Run Application with Podman

### 3.1 Understanding the Setup

Your application has two components:

1. **MySQL Database** - Stores messages
2. **Flask Application** - Web interface

Both will run in separate containers but communicate with each other.

### 3.2 Start the Application

```bash
# Make sure you're in the project directory
cd /Users/mirzaabdulganibaig/Documents/devops/two-tier/DevOps-Project-Two-Tier-Flask-App

# Start all services with podman-compose
podman-compose up -d
```

**What happens:**

```
Creating network two-tier_two-tier-nt
Creating volume two-tier_mysql_data
Pulling mysql image...
Building flask-app image...
Creating container mysql...
Waiting for MySQL to be healthy...
Creating container two-tier-app...
```

**This will take 2-3 minutes on first run** (downloading images and building).

### 3.3 Monitor the Startup

```bash
# Watch the logs in real-time
podman-compose logs -f

# Or check specific service logs
podman-compose logs mysql
podman-compose logs flask-app
```

**Wait until you see:**

```
mysql      | ready for connections
flask-app  | * Running on http://0.0.0.0:5000
```

Press `Ctrl+C` to stop watching logs.

### 3.4 Check Container Status

```bash
# List running containers
podman ps

# Check with podman-compose
podman-compose ps
```

**Expected output:**

```
NAME            IMAGE                    STATUS          PORTS
mysql           docker.io/library/mysql  Up 2 minutes    0.0.0.0:3306->3306/tcp
two-tier-app    localhost/flask-app      Up 1 minute     0.0.0.0:5000->5000/tcp
```

---

## ✅ Step 4: Verify Application

### 4.1 Check Health Endpoints

```bash
# Check Flask app health
curl http://localhost:5000/health

# Expected response:
# {"status":"healthy","database":"connected"}
```

### 4.2 Access the Application

**Open your web browser and go to:**

```
http://localhost:5000
```

**You should see:**

- A web page with "Mirza Abdul Gani Baig | DevOps Enthusiast"
- A message input box
- Any previously submitted messages

### 4.3 Test the Application

1. **Type a message** in the input box (e.g., "Hello from my Mac!")
2. **Click "Send"**
3. **Your message should appear** in the messages list
4. **Refresh the page** - message should still be there (stored in MySQL)

### 4.4 Verify Database Connection

```bash
# Connect to MySQL container
podman exec -it mysql mysql -uroot -proot devops

# Inside MySQL, run:
SHOW TABLES;
SELECT * FROM messages;
EXIT;
```

**You should see your messages stored in the database!**

---

## 🎉 Success! Your App is Running Locally

```
┌─────────────────────────────────────────┐
│     Your Mac (localhost)                │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Browser: http://localhost:5000   │ │
│  └──────────────┬────────────────────┘ │
│                 │                       │
│                 ▼                       │
│  ┌───────────────────────────────────┐ │
│  │  Flask Container (Port 5000)      │ │
│  │  - Handles web requests           │ │
│  │  - Renders HTML                   │ │
│  └──────────────┬────────────────────┘ │
│                 │                       │
│                 ▼                       │
│  ┌───────────────────────────────────┐ │
│  │  MySQL Container (Port 3306)      │ │
│  │  - Stores messages                │ │
│  │  - Data persists in volume        │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## 🛠️ Step 5: Common Operations

### Start/Stop Application

```bash
# Stop the application
podman-compose down

# Start the application
podman-compose up -d

# Restart a specific service
podman-compose restart flask-app

# View logs
podman-compose logs -f
```

### Clean Up (Remove Everything)

```bash
# Stop and remove containers, networks
podman-compose down

# Remove containers, networks, AND volumes (deletes database data!)
podman-compose down -v

# Remove all images
podman rmi flask-app mysql
```

### Rebuild After Code Changes

```bash
# If you modify app.py or Dockerfile
podman-compose down
podman-compose up -d --build
```

---

## 🐛 Troubleshooting

### Issue 1: Port Already in Use

**Error:** `Error: address already in use`

**Solution:**

```bash
# Check what's using port 5000
lsof -i :5000

# Kill the process (replace PID with actual number)
kill -9 <PID>

# Or use different ports in docker-compose.yml:
# Change "5000:5000" to "5001:5000"
```

### Issue 2: MySQL Not Ready

**Error:** `Can't connect to MySQL server`

**Solution:**

```bash
# Check MySQL logs
podman-compose logs mysql

# Wait longer for MySQL to start (it takes 30-60 seconds)
# Check health status
podman inspect mysql | grep -A 10 Health
```

### Issue 3: Podman Machine Not Running

**Error:** `Cannot connect to Podman`

**Solution:**

```bash
# Check machine status
podman machine list

# Start the machine
podman machine start

# If issues persist, restart
podman machine stop
podman machine start
```

### Issue 4: Build Fails

**Error:** `Error building image`

**Solution:**

```bash
# Check Dockerfile syntax
cat Dockerfile

# Try building manually
podman build -t flask-app .

# Check for missing files
ls -la requirement.txt app.py templates/
```

### Issue 5: Health Check Fails

**Error:** `Unhealthy container`

**Solution:**

```bash
# Check if health endpoint exists
curl http://localhost:5000/health

# If 404, you need to add the health endpoint to app.py
# See Step 2.3 above

# Check Flask logs
podman-compose logs flask-app
```

### Issue 6: Database Data Lost

**Problem:** Messages disappear after restart

**Solution:**

```bash
# Make sure you're NOT using -v flag
podman-compose down    # Good - keeps data
# NOT: podman-compose down -v  # Bad - deletes data

# Check if volume exists
podman volume ls

# Backup database
podman exec mysql mysqldump -uroot -proot devops > backup.sql
```

---

## 📊 Useful Commands Reference

### Podman Commands

```bash
# List containers
podman ps
podman ps -a  # Include stopped containers

# List images
podman images

# List volumes
podman volume ls

# List networks
podman network ls

# View container logs
podman logs mysql
podman logs two-tier-app

# Execute command in container
podman exec -it mysql bash
podman exec -it two-tier-app sh

# Inspect container
podman inspect mysql

# Remove container
podman rm -f mysql

# Remove image
podman rmi flask-app

# Remove volume
podman volume rm two-tier_mysql_data

# Clean up everything
podman system prune -a
```

### Podman Compose Commands

```bash
# Start services
podman-compose up -d

# Stop services
podman-compose down

# View logs
podman-compose logs
podman-compose logs -f  # Follow logs

# List services
podman-compose ps

# Restart service
podman-compose restart flask-app

# Rebuild and start
podman-compose up -d --build

# Scale service
podman-compose up -d --scale flask-app=3
```

---

## 🎯 Next Steps - AWS Deployment

Now that your app works locally, you can follow the README.md to deploy on AWS:

### Phase 1: Local Development (✅ DONE!)

- ✅ Install Podman
- ✅ Run app locally
- ✅ Test functionality
- ✅ Understand the architecture

### Phase 2: AWS Preparation (Next)

1. **Create AWS Account** (if you don't have one)
2. **Launch EC2 Instance** (Ubuntu 22.04)
3. **Configure Security Groups** (ports 22, 80, 5000, 8080)
4. **SSH into EC2 instance**

### Phase 3: Install Dependencies on EC2

```bash
# On EC2 instance
sudo apt update && sudo apt upgrade -y
sudo apt install git docker.io docker-compose-v2 -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
```

### Phase 4: Deploy Application on EC2

```bash
# Clone your repository
git clone <your-repo-url>
cd DevOps-Project-Two-Tier-Flask-App

# Run with Docker (same commands as Podman!)
docker compose up -d

# Access at: http://<ec2-public-ip>:5000
```

### Phase 5: Setup Jenkins CI/CD

Follow the README.md steps 3-5 for Jenkins setup.

---

## 📝 Quick Start Cheat Sheet

```bash
# 1. Install Podman (one-time)
brew install podman podman-compose
podman machine init
podman machine start

# 2. Navigate to project
cd /Users/mirzaabdulganibaig/Documents/devops/two-tier/DevOps-Project-Two-Tier-Flask-App

# 3. Start application
podman-compose up -d

# 4. Check status
podman-compose ps
podman-compose logs -f

# 5. Access application
open http://localhost:5000

# 6. Stop application
podman-compose down

# 7. Clean up (removes data!)
podman-compose down -v
```

---

## 🎓 What You've Learned

By completing this local setup, you now understand:

1. ✅ **Containerization** - How to package applications in containers
2. ✅ **Multi-container Apps** - How Flask and MySQL work together
3. ✅ **Podman** - Docker alternative for running containers
4. ✅ **Networking** - How containers communicate
5. ✅ **Volumes** - How to persist data
6. ✅ **Health Checks** - How to verify services are ready
7. ✅ **Troubleshooting** - How to debug container issues

**You're now ready to deploy this on AWS!** 🚀

---

## 💡 Pro Tips

1. **Always check logs** when something doesn't work:
   
   ```bash
   podman-compose logs -f
   ```
2. **Use health checks** to ensure services are ready:
   
   ```bash
   curl http://localhost:5000/health
   ```
3. **Backup your data** before cleaning up:
   
   ```bash
   podman exec mysql mysqldump -uroot -proot devops > backup.sql
   ```
4. **Test locally first** before deploying to AWS - it's free and faster!
5. **Keep your Podman machine running** for better performance:
   
   ```bash
   podman machine list
   ```
6. **Monitor resource usage**:
   
   ```bash
   podman stats
   ```

---

## 🆘 Need Help?

If you encounter issues:

1. **Check the logs**: `podman-compose logs -f`
2. **Verify containers are running**: `podman ps`
3. **Check health status**: `curl http://localhost:5000/health`
4. **Restart services**: `podman-compose restart`
5. **Clean start**: `podman-compose down && podman-compose up -d`

---

## 🎉 Congratulations!

You've successfully set up and run the Flask Two-Tier application locally on your Mac using Podman!

**Next:** Follow the README.md to deploy this same application on AWS EC2 with Jenkins CI/CD pipeline.

Good luck with your DevOps journey! 🚀


