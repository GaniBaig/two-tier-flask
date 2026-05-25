# Jenkins Docker Permission Denied Issue

## Problem Summary

The Jenkins pipeline failed during Docker commands with the following error:

```text
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

This happened in the pipeline during commands such as:

- `docker system prune -f`
- `docker system df`
- `docker ps -a`
- `docker volume prune -f`

## Why This Happened

Jenkins runs the pipeline using the `jenkins` system user.

Docker commands require access to the Docker socket:

```text
/var/run/docker.sock
```

The `jenkins` user did not have permission to access Docker, so every Docker command failed.

## Symptoms Seen in Jenkins Console

Typical failures looked like this:

```text
+ docker system prune -f
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

Because the pipeline depends on Docker commands, the build stopped early and the later stages were skipped.

## Root Cause

The `jenkins` user was not part of the `docker` group.

Without membership in the `docker` group, Jenkins cannot communicate with the Docker daemon.

## Resolution Steps

Run the following commands on the Jenkins server:

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
sudo systemctl restart docker
```

## Verification Steps

After applying the fix, switch to the Jenkins user and test Docker access:

```bash
sudo su - jenkins
docker ps
docker system df
```

If these commands return without a permission error, the fix is successful.

## Actual Validation Observed

The following sequence was used:

```bash
ubuntu@ip-172-31-3-123:~$ docker system prune -f
Total reclaimed space: 0B

ubuntu@ip-172-31-3-123:~$ sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
sudo systemctl restart docker

ubuntu@ip-172-31-3-123:~$ sudo su - jenkins
docker ps
docker system df
jenkins@ip-172-31-3-123:~$
```

Since the prompt returned without the previous permission-denied error, Docker access for Jenkins was restored.

## Expected Outcome After Fix

After this change:

- Jenkins can execute Docker commands
- Pre-build cleanup can run successfully
- Docker Compose deployment can proceed
- Post-build Docker inspection commands should work

## Recommended Jenkinsfile Hardening

Even after fixing permissions, it is safer to make non-critical diagnostic commands non-blocking.

Example:

```groovy
sh 'docker system prune -f || true'
sh 'docker system df || true'
sh 'docker ps -a || true'
sh 'docker volume prune -f || true'
```

This prevents summary or cleanup commands from failing the whole pipeline when they are not essential.

## Quick Interview Answer

**Issue:** Jenkins pipeline failed with Docker socket permission denied.  
**Cause:** `jenkins` user was not in the `docker` group.  
**Fix:** Add `jenkins` to the Docker group and restart Jenkins and Docker.  
**Verification:** Run `docker ps` and `docker system df` as the `jenkins` user.

## One-Line Fix

```bash
sudo usermod -aG docker jenkins && sudo systemctl restart jenkins && sudo systemctl restart docker