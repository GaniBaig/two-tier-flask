# EC2 Disk Space Debugging Guide

## Problem
Jenkins pipeline failed with error: **"No space left on device"**

This happens when your EC2 instance runs out of disk space, typically caused by:
- Docker images accumulating over time
- Docker containers and volumes
- Jenkins build artifacts and logs
- System logs

---

## Step 1: Check Overall Disk Usage

SSH into your EC2 instance and run:

```bash
df -h
```

**What to look for:**
- Check the **Use%** column for your root filesystem (usually `/` or `/dev/xvda1`)
- If it's above 90%, you need to free up space

**Example output:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1       8G   7.5G  500M  94% /
```

---

## Step 2: Find What's Using Space

### Check Docker Space Usage

```bash
docker system df
```

**Output shows:**
- Images: Space used by Docker images
- Containers: Space used by containers
- Volumes: Space used by Docker volumes
- Build Cache: Space used by build cache

**Example:**
```
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          15        2         4.5GB     3.2GB (71%)
Containers      5         2         1.2GB     800MB (66%)
Local Volumes   3         1         500MB     300MB (60%)
Build Cache     0         0         0B        0B
```

### Check Directory Sizes

Find the largest directories:

```bash
sudo du -h --max-depth=1 / 2>/dev/null | sort -hr | head -20
```

Common space hogs:
- `/var/lib/docker` - Docker data
- `/var/lib/jenkins` - Jenkins data
- `/var/log` - System and application logs

---

## Step 3: Clean Up Docker Resources

### Option 1: Clean Everything (Recommended for Development)

**⚠️ WARNING: This removes ALL unused Docker resources**

```bash
# Stop running containers first
docker compose down

# Remove all unused images, containers, volumes, and networks
docker system prune -a --volumes -f
```

**What this removes:**
- All stopped containers
- All networks not used by at least one container
- All images without at least one container associated
- All build cache
- All volumes not used by at least one container

### Option 2: Selective Cleanup (Safer for Production)

**Remove stopped containers:**
```bash
docker container prune -f
```

**Remove unused images:**
```bash
docker image prune -a -f
```

**Remove unused volumes:**
```bash
docker volume prune -f
```

**Remove build cache:**
```bash
docker builder prune -a -f
```

### Option 3: Remove Specific Old Images

List all images:
```bash
docker images
```

Remove specific image:
```bash
docker rmi <image-id>
```

Remove images older than 24 hours:
```bash
docker image prune -a --filter "until=24h" -f
```

---

## Step 4: Clean Up Jenkins Data

### Check Jenkins Workspace Size

```bash
sudo du -sh /var/lib/jenkins/workspace/*
```

### Clean Old Jenkins Builds

```bash
# Remove old build artifacts (keeps last 5 builds)
sudo find /var/lib/jenkins/jobs/*/builds/ -type d -mtime +7 -exec rm -rf {} +
```

### Clean Jenkins Logs

```bash
sudo find /var/lib/jenkins/jobs/*/builds/*/log -type f -mtime +7 -delete
```

---

## Step 5: Clean System Logs

```bash
# Check log sizes
sudo du -sh /var/log/*

# Clean old logs
sudo journalctl --vacuum-time=3d
sudo find /var/log -type f -name "*.log" -mtime +7 -delete
sudo find /var/log -type f -name "*.gz" -delete
```

---

## Step 6: Verify Space is Freed

```bash
df -h
```

You should see increased available space.

---

## Step 7: Prevent Future Issues

### 1. Add Docker Cleanup to Cron Job

Create a weekly cleanup script:

```bash
sudo nano /etc/cron.weekly/docker-cleanup
```

Add this content:
```bash
#!/bin/bash
docker system prune -f --filter "until=168h"
docker volume prune -f --filter "until=168h"
```

Make it executable:
```bash
sudo chmod +x /etc/cron.weekly/docker-cleanup
```

### 2. Configure Jenkins to Limit Build History

In Jenkins:
1. Go to your job configuration
2. Under "Discard old builds"
3. Set "Max # of builds to keep" to 5-10

### 3. Add Jenkinsfile Cleanup Stage

Update your Jenkinsfile to clean up after deployment:

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
        
        stage('Cleanup') {
            steps {
                sh 'docker image prune -f --filter "dangling=true"'
            }
        }
    }
    
    post {
        always {
            sh 'docker system df'
        }
    }
}
```

### 4. Monitor Disk Space

Add monitoring script:

```bash
sudo nano /usr/local/bin/check-disk-space.sh
```

Content:
```bash
#!/bin/bash
THRESHOLD=80
USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ $USAGE -gt $THRESHOLD ]; then
    echo "WARNING: Disk usage is at ${USAGE}%"
    echo "Running cleanup..."
    docker system prune -f --filter "until=72h"
fi
```

Make executable and add to cron:
```bash
sudo chmod +x /usr/local/bin/check-disk-space.sh
echo "0 */6 * * * /usr/local/bin/check-disk-space.sh" | sudo crontab -
```

---

## Step 8: Consider Increasing EC2 Storage

If cleanup doesn't help long-term:

### Option 1: Resize Existing Volume

1. Go to AWS EC2 Console
2. Select your instance → Storage tab
3. Click on the volume ID
4. Actions → Modify Volume
5. Increase size (e.g., from 8GB to 20GB)
6. SSH into instance and extend filesystem:

```bash
# For Ubuntu/Debian
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1

# Verify
df -h
```

### Option 2: Use Larger Instance Type

When launching new instances, choose:
- **t2.small** or **t2.medium** instead of t2.micro
- These come with more storage by default

---

## Quick Reference Commands

```bash
# Check disk space
df -h

# Check Docker space
docker system df

# Clean everything (development)
docker system prune -a --volumes -f

# Clean safely (production)
docker container prune -f
docker image prune -a -f
docker volume prune -f

# Check what's using space
sudo du -h --max-depth=1 / 2>/dev/null | sort -hr | head -10

# Clean logs
sudo journalctl --vacuum-time=3d
```

---

## Troubleshooting

### After cleanup, still no space?

Check for large files:
```bash
sudo find / -type f -size +100M 2>/dev/null | xargs ls -lh
```

### Docker daemon won't start after cleanup?

```bash
sudo systemctl restart docker
sudo systemctl status docker
```

### Jenkins won't start?

```bash
sudo systemctl restart jenkins
sudo systemctl status jenkins
```

---

## Best Practices

1. **Regular Cleanup**: Run `docker system prune` weekly
2. **Limit Builds**: Keep only last 5-10 Jenkins builds
3. **Monitor Space**: Set up alerts when disk usage > 80%
4. **Use Volumes Wisely**: Don't create unnecessary Docker volumes
5. **Log Rotation**: Enable log rotation for all services
6. **Right-Size Instance**: Use appropriate EC2 instance size for your workload

---

## Summary

Your Jenkins pipeline failed because the EC2 instance ran out of disk space while extracting Docker images. The main culprits are usually:

1. **Old Docker images** (biggest space consumer)
2. **Docker build cache**
3. **Jenkins build artifacts**
4. **System logs**

**Immediate fix:**
```bash
docker system prune -a --volumes -f
```

**Long-term solution:**
- Set up automated cleanup
- Monitor disk usage
- Consider increasing storage if needed