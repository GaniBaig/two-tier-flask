# EC2 Jenkins Memory Pressure, Swap, and Instance Sizing Guide

## Problem Summary

The EC2 instance became slow or unresponsive whenever a Jenkins job was triggered.  
This is primarily a **memory pressure** problem, not a storage problem.

Initial system state:

```bash
ubuntu@ip-172-31-3-123:~$ uptime
free -h
df -h
 10:58:06 up 5 min,  1 user,  load average: 9.86, 4.28, 1.70
               total        used        free      shared  buff/cache   available
Mem:           951Mi       945Mi        30Mi       6.7Mi        68Mi       6.6Mi
Swap:             0B          0B          0B
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        19G  6.3G   12G  35% /
```

### What this means

- Disk was **not** the current bottleneck:
  - `19G total`
  - `12G free`
- RAM was the actual issue:
  - only about `6.6Mi` available memory
- Swap was missing:
  - `Swap: 0B`
- Load was very high:
  - `load average: 9.86` on a very small instance

This is why the EC2 instance stopped responding well during Jenkins builds.

---

## Why the Instance Became Unresponsive

On a small EC2 instance like `t3.micro`, Jenkins + Docker builds consume memory very quickly.

### Main memory consumers

When you trigger a Jenkins job, memory is used by:

1. **Jenkins Java process**
   - Jenkins itself runs on Java
   - Java heap can consume a large part of RAM if not limited

2. **Docker daemon**
   - Docker engine needs memory to manage builds, images, layers, containers, and networks

3. **Docker build process**
   - `docker compose up -d --build`
   - building the Flask image uses memory during:
     - package download
     - compiling Python dependencies
     - layer creation
     - unpacking image layers

4. **MySQL container**
   - MySQL needs memory for startup and health checks

5. **Flask application container**
   - application startup and DB connection add more memory usage

6. **Operating system**
   - Ubuntu itself needs memory for:
     - kernel
     - page cache
     - networking
     - SSH session
     - systemd
     - journald

### Why EC2 feels frozen

When RAM is almost exhausted and there is no swap:

- SSH becomes slow
- Docker commands hang
- Jenkins becomes unresponsive
- builds appear stuck
- processes may be killed by the kernel OOM killer
- CPU usage can spike because the system is struggling under pressure

---

## Storage Was Fixed, But Memory Was Still Critical

You already solved the storage concern.

Observed disk state:

```bash
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        19G  6.3G   12G  35% /
```

So disk space was healthy.

But memory remained critically low:

```bash
Mem:           951Mi       945Mi        30Mi
available:     6.6Mi
Swap:             0B
```

That is the real reason Jenkins jobs made the machine unstable.

---

## Recommended Solution Paths

You have two choices.

### Option 1 — Recommended: Upgrade EC2 instance type

Change:

- `t3.micro`
- to `t3.small`

### Why this is better

`t3.small` gives:

- `2 GB RAM`
- more breathing room for Jenkins
- smoother Docker builds
- less swap dependency
- much more stable Jenkins behavior

### Recommended instance sizing for this project

For learning/demo usage:

- `t3.small`
- `20 GB` storage

This is the best balance of cost and stability.

---

### Option 2 — Stay on t3.micro

If you continue using `t3.micro`, then swap is mandatory.

Because the instance was recreated, the old swap was lost.

---

## Step 1: Add 2 GB Swap

Run:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### What each command does

#### `sudo fallocate -l 2G /swapfile`
Creates a 2 GB file named `/swapfile`.

#### `sudo chmod 600 /swapfile`
Restricts permissions so only root can access the swap file.

#### `sudo mkswap /swapfile`
Formats the file as swap space.

#### `sudo swapon /swapfile`
Activates the swap file immediately.

---

## Step 2: Make Swap Persistent After Reboot

Run:

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### What this does

This adds a permanent entry to `/etc/fstab` so the swap file is automatically enabled after every reboot.

---

## Step 3: Verify Swap

Run:

```bash
free -h
```

Expected result should include swap, for example:

```bash
Swap:          2.0Gi
```

---

## Step 4: Reduce Jenkins Memory Usage

On small instances, Jenkins Java heap must be limited.

Run:

```bash
sudo systemctl edit jenkins
```

You may see a commented example like:

```ini
# # Arguments for the Jenkins JVM
# Environment="JAVA_OPTS=-Djava.awt.headless=true"
```

Add this below it:

```ini
[Service]
Environment="JAVA_OPTS=-Xms256m -Xmx512m -Djava.awt.headless=true"
```

Final override content should effectively be:

```ini
[Service]
Environment="JAVA_OPTS=-Xms256m -Xmx512m -Djava.awt.headless=true"
```

### What this does

- `-Xms256m` → start Jenkins heap at 256 MB
- `-Xmx512m` → cap Jenkins heap at 512 MB
- `-Djava.awt.headless=true` → run Java without GUI requirements

This prevents Jenkins from consuming too much memory on a small EC2 instance.

---

## Step 5: Reload and Restart Jenkins

Run:

```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

Then verify:

```bash
systemctl status jenkins
```

---

## Step 6: Verify Improved Memory State

Run:

```bash
free -h
```

Observed improved state:

```bash
ubuntu@ip-172-31-3-123:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:           951Mi       715Mi        61Mi       6.5Mi       294Mi       236Mi
Swap:          2.0Gi       352Mi       1.7Gi
```

### Why this is much better

Before:

- available memory was about `6Mi`

After:

- available memory became about `236Mi`
- swap absorbed pressure
- system stability improved significantly

---

## Where Does the “Extra Memory” Come From?

This is an important question.

EC2 instance RAM does **not** increase automatically.

The extra usable headroom comes from two places:

### 1. Swap space
Swap uses disk as overflow memory.

That means when RAM fills up, Linux can move less-active memory pages from RAM to disk-backed swap.

So:

- physical RAM is still `951Mi`
- but Linux now has an extra `2Gi` of virtual memory backing from disk

This is why the system survives heavy pressure instead of freezing immediately.

### 2. Reduced Jenkins heap
By limiting Jenkins Java memory:

```ini
-Xms256m -Xmx512m
```

Jenkins stops taking too much RAM.

That frees more RAM for:

- Docker daemon
- image builds
- MySQL container
- Flask container
- operating system

So the “extra usable memory” is not new EC2 RAM.  
It comes from:

- **swap on disk**
- **better memory allocation**
- **less waste by Jenkins**

---

## Why the EC2 Instance Still May Feel Slow

Even after swap is enabled, `t3.micro` remains a small machine.

### Reasons

1. **Swap is slower than RAM**
   - swap is disk-backed
   - it improves survival, not performance

2. **Docker builds are CPU and memory intensive**
   - package installs
   - Python wheel builds
   - image layer creation

3. **CPU credits may drain on burstable instances**
   - when credits are low, performance drops
   - builds become slow

4. **MySQL + Jenkins + Docker together are heavy for micro**
   - multiple services compete for limited RAM and CPU

So swap helps prevent crashes, but it does not make `t3.micro` fast.

---

## Why CloudWatch Showed High CPU and Credit Drain

Observed behavior:

- CPU spikes toward 100%
- CPU credits draining
- sustained load

This confirms the instance was under continuous stress.

On `t3.micro`, this is expected when running:

- Jenkins
- Docker builds
- MySQL
- Flask app
- package compilation

---

## Monitoring Commands During Build

Open another SSH session and run:

```bash
watch free -h
```

and:

```bash
top
```

### What to expect

During Jenkins build:

- free RAM may drop
- swap usage may increase
- CPU may spike
- build may still complete slowly

That is normal on `t3.micro`.

---

## If Build Pauses During pip Install

If Jenkins appears stuck around:

```dockerfile
RUN pip install --no-cache-dir -r requirement.txt
```

it may not be frozen; it may just be slow due to memory and CPU pressure.

### Recommended Dockerfile improvement

Change:

```dockerfile
RUN pip install --no-cache-dir -r requirement.txt
```

to:

```dockerfile
RUN pip install --upgrade pip setuptools wheel && \
    pip install -v --default-timeout=100 --no-cache-dir -r requirement.txt
```

### What this improves

- verbose logs
- clearer build progress
- better dependency handling
- fewer silent-looking stalls

---

## If Build Still Fails

Run immediately after failure:

```bash
docker ps -a
sudo journalctl -u jenkins -n 100 --no-pager
```

### Why this helps

This can reveal:

- OOM kills
- Jenkins service problems
- Docker failures
- pip compilation errors
- crashed containers

---

## Current Environment Status Summary

| Resource | Status |
|---|---|
| Disk | Good |
| Network | Good |
| Jenkins | Stable after tuning |
| Docker | Stable |
| RAM | Tight but workable |
| Swap | Correctly configured |

---

## Final Recommendation

### Best setup for this project

For learning/demo workloads:

- **EC2 type:** `t3.small`
- **Storage:** `20 GB`

This is the best balance of:

- cost
- performance
- Jenkins usability
- Docker build reliability

### If staying on t3.micro

You must:

- keep swap enabled
- limit Jenkins JVM memory
- expect slower builds
- monitor memory during builds
- avoid unnecessary heavy packages/images

---

## Interview-Ready Short Explanation

**Issue:** EC2 became unresponsive when Jenkins jobs ran.  
**Root cause:** Memory exhaustion on a small `t3.micro` instance running Jenkins, Docker builds, MySQL, and the app container.  
**Why disk was not the issue:** Disk had 12 GB free.  
**Fix:** Added 2 GB swap, reduced Jenkins JVM heap, and recommended upgrading to `t3.small`.  
**Where extra usable memory came from:** Not from EC2 RAM increase, but from Linux swap plus reduced Jenkins heap usage.  
**Best recommendation:** Use `t3.small` for Jenkins + Docker projects.

---

## Quick Command Summary

### Add swap
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Limit Jenkins memory
```bash
sudo systemctl edit jenkins
```

Add:
```ini
[Service]
Environment="JAVA_OPTS=-Xms256m -Xmx512m -Djava.awt.headless=true"
```

Then apply:
```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
systemctl status jenkins
```

### Monitor system
```bash
free -h
watch free -h
top
docker ps -a
sudo journalctl -u jenkins -n 100 --no-pager