# Troubleshooting Methodology

A repeatable process for diagnosing and resolving AWS incidents.
Each step helps build situational awareness, cut down on guesswork, and focus on evidence.

## 1. Detect

**Identify that something’s wrong using monitoring:**

- CloudWatch alarms (CPU, memory, disk, health checks)
- Dashboard anomalies
- Application errors or latency
- AWS Console
- Direct application observation 

---

## 2. Scope

**Determine what's affected:**

- One instance or all instances?
- Application layer or infrastructure layer?
- Networking, permissions, or configuration?
- Use metrics, target group health, and ASG activity to tell whether it’s isolated or systemic.

---

## 3. Investigate

Work from **infrastructure → service → application → monitoring**.

**Common checks:**

- EC2: `systemctl status`, `journalctl`, instance status checks
- Network: `curl`, `nc`, `ping`, `mysql -h` to verify reachability
- Application: Check `/var/log/httpd/error_log` or `/var/log/cloud-init-output.log`
- Monitoring: Verify CloudWatch agent, alarm state, and metric updates

---

## 4. Identify Cause

Use symptoms and logs to pinpoint the root issue.

**Examples:**

- Service crash due to missing dependency
- Disk full preventing write operations
- Incorrect security group rule blocking traffic
- ASG launch failure due to user data typo

---

## 5. Validate Fix

**Before applying a full resolution:**

- Test potential fixes on one instance or a controlled environment
- Monitor logs and metrics for side effects
- Verify app accessibility and service health checks

Confirm the fix works without introducing new problems.

---

## 6. Resolve

**Apply the final solution:**

- Restart or reconfigure affected services
- Update launch templates, user data, or CloudWatch settings
- Re-enable suspended ASG processes
- Document command history for reproducibility

---

## 7. Verify

**Confirm the issue is fully resolved:**

- CloudWatch alarms cleared
- Metrics stable and trending normally
- Target groups healthy
- Logs quiet

---

## 8. Document

**Record:**

- What triggered the issue
- What caused it
- What fixed it
- What you’d change next time

Turn incidents into reusable learning material.

---

## Command Reference

| **Layer** | **Common Commands** | 
| ----- | --------------- |
| **System** | `top`, `free`, `ps aux`, `systemctl`, `journalctl`, `pkill`|
| **Disk** | `df -h`, `du -sh /* \| sort -h`, `lsof` |
| **Network** | `curl -I`, `ping`, `nc -zv`, `ss -tuln` |
| **Application** | `tail -n 50 /var/log/httpd/error_log`, `cat /var/log/cloud-init-output.log` |
| **AWS CLI** | `aws autoscaling describe-auto-scaling-groups`, `aws cloudwatch describe-alarms`, `aws ec2 describe-instances` |

---

## Key Principles

- **Start simple:** Check obvious causes first: services, security groups, or typos.
- **Stay systematic:** Don’t jump layers until you’ve ruled out the current one.
- **Keep evidence:** Save commands, timestamps, and observations in notes as you go.
- **Reflect afterward:** A fix isn’t complete until you understand why it worked.

This is the same process I followed in every incident—starting from signals, narrowing down scope, and working methodically until the root cause was clear.