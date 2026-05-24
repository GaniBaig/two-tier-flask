# Your EC2 Disk Space Analysis & Solution

## Current Disk Status

```
Filesystem       Size  Used Avail Use% Mounted on
/dev/root        6.7G  5.6G  1.1G  85% /
```

**Status:** ⚠️ **CRITICAL** - 85% disk usage with only 1.1GB free

## Space Breakdown

```
Total Disk: 6.7GB
Used: 5.6GB (85%)
Available: 1.1GB (15%)

Directory Usage:
- /usr:  3.2GB (50% of total) - System binaries and libraries
- /var:  1.4GB (22% of total) - Logs, Docker data, Jenkins data
- /snap: 658MB (10% of total) - Snap packages
- /boot: 101MB
- /tmp:  52MB
```

## Docker Status

```
Images:     2 images, 559.8MB total (93.14MB reclaimable)
Containers: 0 (all stopped)
Volumes:    0
Build Cache: 0
```

**Good news:** Docker is relatively clean, but you have 2 images taking 560MB.

---

## Problem Analysis

Your 6.7GB disk is too small for a Jenkins + Docker setup. Here's why you're at 85%:

1. **Base Ubuntu System**: ~3.2GB in `/usr`
2. **Jenkins + Docker + Logs**: ~1.4GB in `/var`
3. **Snap packages**: ~658MB
4. **Only 1.1GB free** - Not enough for:
   - Pulling new Docker images (MySQL alone is ~162MB compressed, ~500MB extracted)
   - Building Docker images
   - Jenkins workspace and build artifacts

---

## Immediate Actions Required

### Step 1: Deep Dive into /var (Where Docker & Jenkins Live)

```bash
sudo du -h --max-depth=2 /var 2>/dev/null | sort -hr | head -20
```

This will show you:
- `/var/lib/docker` - Docker images, containers, volumes
- `/var/lib/jenkins` - Jenkins data
- `/var/log` - System and application logs

### Step 2: Check Specific Space Hogs

**Check Jenkins workspace:**
```bash
sudo du -sh /var/lib/jenkins/workspace/*
sudo du -sh /var/lib/jenkins/jobs/*/builds/*
```

**Check Docker specifically:**
```bash
sudo du -sh /var/lib/docker/*
```

**Check logs:**
```bash
sudo du -sh /var/log/*
```

### Step 3: Clean Up What You Can

**Clean old logs:**
```bash
# Clean journal logs (keeps last 3 days)
sudo journalctl --vacuum-time=3d

# Clean old log files
sudo find /var/log -type f -name "*.log" -mtime +7 -exec truncate -s 0 {} \;
sudo find /var/log -type f -name "*.gz" -delete
sudo find /var/log -type f -name "*.1" -delete
```

**Clean apt cache:**
```bash
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y
```

**Clean snap old versions:**
```bash
# Remove old snap versions
sudo snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
    sudo snap remove "$snapname" --revision="$revision"
done
```

**Clean Docker build cache (if any builds were done):**
```bash
docker builder prune -a -f
```

### Step 4: Check Space After Cleanup

```bash
df -h
```

---

## Long-Term Solutions

### Option 1: Increase EBS Volume Size (RECOMMENDED)

Your current volume is only **6.7GB** which is too small. Increase it to **20GB**:

#### Steps to Resize:

1. **In AWS Console:**
   - Go to EC2 → Instances
   - Select your instance
   - Go to Storage tab
   - Click on the Volume ID
   - Actions → Modify Volume
   - Change size from 8GB to 20GB
   - Click Modify

2. **On EC2 Instance (after modification):**
   ```bash
   # Check current size
   lsblk
   
   # Grow the partition
   sudo growpart /dev/nvme0n1 1
   
   # Resize the filesystem
   sudo resize2fs /dev/nvme0n1p1
   
   # Verify new size
   df -h
   ```

**Cost Impact:** Minimal - EBS storage costs ~$0.10/GB/month
- 8GB → 20GB = additional 12GB = ~$1.20/month extra

### Option 2: Use Larger EC2 Instance Type

When launching new instances:
- **t2.micro**: 8GB storage (too small for Docker + Jenkins)
- **t2.small**: 20GB storage (recommended minimum)
- **t2.medium**: 30GB storage (comfortable for development)

### Option 3: Add Automated Cleanup to Jenkins

Update your Jenkinsfile to clean up after each build:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Clone repo') {
            steps {
                git branch: 'main', url: 'https://github.com/GaniBaig/two-tier-flask.git'
            }
        }
        
        stage('Build image') {
            steps {
                sh 'docker build -t flask-app .'
            }
        }
        
        stage('Deploy with docker compose') {
            steps {
                sh 'docker compose down || true'
                sh 'docker compose up -d --build'
            }
        }
        
        stage('Cleanup Old Images') {
            steps {
                // Remove dangling images
                sh 'docker image prune -f'
                
                // Remove images older than 7 days
                sh 'docker image prune -a -f --filter "until=168h"'
            }
        }
    }
    
    post {
        always {
            // Show disk usage after build
            sh 'df -h'
            sh 'docker system df'
        }
        
        failure {
            // Extra cleanup on failure
            sh 'docker system prune -f'
        }
    }
}
```

---

## Recommended Action Plan

### Immediate (Do Now):

1. **Clean logs and cache:**
   ```bash
   sudo journalctl --vacuum-time=3d
   sudo apt-get clean
   sudo apt-get autoremove -y
   ```

2. **Check what's in /var:**
   ```bash
   sudo du -h --max-depth=2 /var | sort -hr | head -20
   ```

3. **Share the output** so we can identify specific space hogs

### Short-term (This Week):

1. **Resize EBS volume to 20GB** (takes 5 minutes, costs $1.20/month)
2. **Update Jenkinsfile** with cleanup stage
3. **Set up automated cleanup cron job**

### Long-term (Best Practice):

1. **Use t2.small or larger** for Jenkins + Docker workloads
2. **Monitor disk usage** with CloudWatch alarms
3. **Implement log rotation** for all services
4. **Regular maintenance** - weekly cleanup

---

## Why 6.7GB is Too Small

**Minimum space requirements:**
- Ubuntu base system: ~3GB
- Docker daemon: ~500MB
- Jenkins: ~500MB
- MySQL Docker image: ~500MB (extracted)
- Flask Docker image: ~200MB
- Build cache and layers: ~1GB
- Logs and temporary files: ~500MB
- **Total needed: ~6.2GB**

**Your current setup:**
- Total: 6.7GB
- Used: 5.6GB
- Free: 1.1GB ❌ Not enough for new builds!

**Recommended minimum:** 20GB
- Gives you ~14GB free space
- Enough for multiple images
- Room for build cache
- Space for logs and artifacts

---

## Next Steps

Run these commands and share the output:

```bash
# Check /var breakdown
sudo du -h --max-depth=2 /var 2>/dev/null | sort -hr | head -20

# Check Jenkins workspace
sudo du -sh /var/lib/jenkins/workspace/* 2>/dev/null

# Check Docker directory
sudo du -sh /var/lib/docker/* 2>/dev/null

# Check logs
sudo du -sh /var/log/* 2>/dev/null | sort -hr | head -10
```

This will help identify exactly what's consuming space so we can make targeted cleanup decisions.

---

## Summary

**Current State:**
- ✅ Docker is clean (only 560MB)
- ❌ Disk is 85% full (only 1.1GB free)
- ❌ 6.7GB total is too small for Jenkins + Docker

**Root Cause:**
- Your EBS volume is undersized for the workload

**Solution:**
1. **Immediate:** Clean logs and cache
2. **Required:** Resize EBS volume to 20GB
3. **Ongoing:** Add cleanup to Jenkins pipeline

**Cost:** ~$1.20/month for additional 12GB storage