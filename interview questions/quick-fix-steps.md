# ✅ Quick Fix - Restart Your Application

## 🎯 What We Fixed

**Problem:** Duplicate `/health` endpoint in app.py causing Flask container to crash

**Solution:** Removed the duplicate endpoint (you had it defined twice!)

---

## 🚀 Steps to Restart Your Application

### Step 1: Stop Everything

```bash
cd /Users/mirzaabdulganibaig/Documents/devops/two-tier/DevOps-Project-Two-Tier-Flask-App

# Stop all containers
podman-compose down
```

### Step 2: Rebuild the Flask Image

```bash
# Rebuild to include the fixed app.py
podman-compose build --no-cache flask-app
```

### Step 3: Start Everything

```bash
# Start all services
podman-compose up -d
```

### Step 4: Watch the Logs

```bash
# Watch logs to see if it starts successfully
podman-compose logs -f
```

**Wait for these messages:**
- MySQL: `ready for connections`
- Flask: `Running on http://0.0.0.0:5001`

Press `Ctrl+C` to stop watching logs.

### Step 5: Verify Both Containers Are Running

```bash
# Check running containers
podman ps
```

**You should see BOTH:**
```
CONTAINER ID  IMAGE         COMMAND   CREATED     STATUS                 PORTS           NAMES
xxxxx         mysql:latest  mysqld    X min ago   Up X min (healthy)    3306/tcp        mysql
xxxxx         flask-app     python... X min ago   Up X min              5001/tcp        two-tier-app
```

### Step 6: Test the Application

```bash
# Test health endpoint
curl http://localhost:5001/health

# Expected response:
# {"status":"healthy","database":"connected"}

# Test main page
curl http://localhost:5001/

# Should return HTML
```

### Step 7: Open in Browser

```bash
# Open in your default browser
open http://localhost:5001
```

**Or manually go to:** `http://localhost:5001`

---

## 🎉 Success!

If you see:
- ✅ Both containers running in `podman ps`
- ✅ Health endpoint returns `{"status":"healthy"}`
- ✅ Web page loads in browser
- ✅ You can submit messages

**Your application is working!** 🎊

---

## 🐛 If It Still Doesn't Work

### Check Logs Again

```bash
# Check Flask logs
podman logs two-tier-app

# Check MySQL logs
podman logs mysql

# Or both together
podman-compose logs
```

### Common Issues

**Issue 1: Container still not running**
```bash
# Check if it's stopped
podman ps -a

# If STATUS shows "Exited", check logs
podman logs two-tier-app
```

**Issue 2: Port 5001 still in use**
```bash
# Check what's using port 5001
lsof -i :5001

# Kill it if needed
lsof -ti :5001 | xargs kill -9
```

**Issue 3: curl not installed in container**
```bash
# Check Dockerfile has curl
grep curl Dockerfile

# If not, add it and rebuild
```

---

## 📋 Complete Command Sequence

Copy and paste this entire block:

```bash
# Navigate to project
cd /Users/mirzaabdulganibaig/Documents/devops/two-tier/DevOps-Project-Two-Tier-Flask-App

# Stop everything
podman-compose down

# Rebuild Flask image
podman-compose build --no-cache flask-app

# Start everything
podman-compose up -d

# Wait 30 seconds for MySQL to be ready
echo "Waiting for services to start..."
sleep 30

# Check status
echo "Checking containers..."
podman ps

# Test health
echo "Testing health endpoint..."
curl http://localhost:5001/health

# Test main page
echo "Testing main page..."
curl -I http://localhost:5001/

echo ""
echo "✅ If you see both containers and health check passed, open:"
echo "   http://localhost:5001"
```

---

## 🔍 What Changed in Your Files

### app.py
- ✅ Removed duplicate `/health` endpoint
- ✅ Kept port 5001
- ✅ Single health endpoint definition

### docker-compose.yml
- ✅ Already configured for port 5001
- ✅ Healthcheck points to port 5001
- ✅ No changes needed

---

## 💡 Why It Failed Before

**The Error:**
```
AssertionError: View function mapping is overwriting an existing endpoint function: health
```

**What It Means:**
- You defined the same route (`/health`) twice
- Flask doesn't allow duplicate route definitions
- The app crashed on startup

**The Fix:**
- Removed the duplicate definition
- Now only one `/health` endpoint exists
- Flask starts successfully

---

## 🎓 Key Learnings

1. **Always check logs first:** `podman logs container-name`
2. **Duplicate routes cause crashes:** Each route must be unique
3. **Rebuild after code changes:** `podman-compose build`
4. **Port mapping:** `"5001:5001"` means host:container
5. **Health checks are important:** They verify the app is actually working

---

## ✅ Final Checklist

- [ ] Stopped old containers (`podman-compose down`)
- [ ] Rebuilt Flask image (`podman-compose build --no-cache flask-app`)
- [ ] Started containers (`podman-compose up -d`)
- [ ] Both containers running (`podman ps` shows mysql AND two-tier-app)
- [ ] Health check passes (`curl http://localhost:5001/health`)
- [ ] Web page loads (`http://localhost:5001` in browser)
- [ ] Can submit messages

---

**You're all set! Your Flask app should now be running on port 5001!** 🚀