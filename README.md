# AWS Incident Response Lab

Hands-on incident simulations designed to build real-world troubleshooting instincts for cloud operations.

## Overview
This repository documents my journey building troubleshooting skills through simulated incidents. I intentionally broke a running AWS environment in multiple ways, then investigated and resolved each issue—documenting everything

- Intentional system failure
- Systematic investigation process
- Root cause analysis
- Resolution and verification
- Detailed incident documentation

## Infrastructure
Built on my existing [aws-cloudwatch-monitoring](https://github.com/odysian/aws-cloudwatch-monitoring) environment:

- **VPC:** Multi-AZ
- **Compute:** Auto Scaling Group (2-4 t3.micro instances)
- **Load Balancer:** Internet-facing Application Load Balancer
- **Database:** RDS MySQL
- **Monitoring:** CloudWatch dashboards, alarms and agent-based metrics
- **Access:** SSM Session Manager

This provided a realistic environment for simulating failure incidents across compute, network, application, database, and monitoring layers.

| # | Incident | Type | Duration | Key Skills |
|---|----------|------|----------|------------|
| 01 | [Web Server Down](incidents/01-web-server-down.md) | Resource Exhaustion | 22 min | Process monitoring, stress testing, CloudWatch alarms |
| 02 | [Database Unreachable](incidents/02-database-unreachable.md) | Network/Security | 15 min | Security groups, RDS connectivity, network troubleshooting |
| 03 | [High CPU Usage](incidents/03-high-cpu-usage.md) | Infrastructure | 15 min | ASG health checks, instance recovery, EC2 status checks |
| 04 | [Disk Space Alert](incidents/04-disk-space-alert.md) | Resource Exhaustion | 11 min | Filesystem investigation, disk monitoring, du/df commands |
| 05 | [ALB 502 Bad Gateway](incidents/05-alb-502-errors.md) | Application | 15 min | Load balancer troubleshooting, health check debugging, Apache logs |
| 06 | [ASG Launch Failure](incidents/06-asg-launch-failure.md) | Configuration | 16 min | Launch templates, user data errors, cloud-init logs |
| 07 | [CloudWatch Agent Failure](incidents/07-cloudwatch-agent-failure.md) | Monitoring | 7 min | Agent troubleshooting, observability dependencies, systemd |

**Total hands-on troubleshooting time:** ~2 hours across 7 incidents, additional time spent discovering possible preventative measures.

## Skills Demonstrated

### AWS Services
- **EC2:** Instance troubleshooting, status checks, SSM/SSH
- **Auto Scaling Groups:** Health checks, launch templates, suspended processes, activity history
- **Application Load Balancer:** Target group health, 502 errors, health check configuration
- **RDS:** Connectivity troubleshooting, security group configuration
- **CloudWatch:** Metrics, alarms, dashboards, agent configuration, logs analysis
- **VPC:** Security groups, network connectivity, subnet routing

### Linux System Administration
- **Service Management:** systemctl, journalctl, service status investigation
- **Process Monitoring:** top, ps, pkill, process resource usage
- **Resource Analysis:** df, du, free, netstat, lsof
- **Network Testing:** nc, telnet, curl, mysql client
- **Log Analysis:** Apache error/access logs, cloud-init logs, system journals

### Operational Skills
- **Systematic Investigation:** Layered approach (infrastructure → service → application)
- **Hypothesis Testing:** Ruling out possibilities methodically
- **Root Cause Analysis:** Following evidence to definitive causes
- **Incident Documentation:** Professional reports suitable for knowledge transfer
- **Preventive Thinking:** Identifying monitoring gaps and improvement opportunities

## Documentation Approach

Each incident follows a consistent structure of incident reports:

- **Incident Summary:** Quick facts (date, duration, severity, impact, root cause)
- **Timeline:** Timestamped progression from incident start to resolution
- **Detection:** How the issue was discovered
- **Investigation Process:** Steps taken, commands run, findings
- **Resolution:** Fix applied and verification steps
- **Lessons Learned:** What worked, what could improve
- **Prevention Strategies:** Improvements for production environments
- **Technical Details:** Commands, logs, configuration details
- **Additional Notes:** Notes include topics I learned about in the process of breaking and resolving the incidents
- **Metrics:** Time to detect, identify root cause, resolve, and verify

## Troubleshooting Methodology

I used a systematic approach for investigating incidents:

1. **Detect:** Spot the problem through alarms, dashboard metrics, or logs.
2. **Scope:** Determine whether single instance, all instances, database, or network.
3. **Investigate:** Work from ground up; start with infrastructure, then services, then app layer.
4. **Identify Cause:** Narrow down what's actually broken based on what the data shows.
5. **Validate Fix:** Try a targeted change and see if it resolves the issue without side effects.
6. **Resolve:** Apply the confirmed fix and clean up any lingering issues.
7. **Verify:** Watch metrics and logs to make sure everything's stable again
8. **Document:** Write down what happened, what fixed it, and what to watch for next time.

See [Troubleshooting Methodology](runbooks/troubleshooting-methodology.md).

## Key Takeaways

### Technical Lessons
- **Health checks happen at multiple layers:** EC2 status checks, ALB target health, and app-level checks work independently, one can fail while the others look fine.
- **Resource exhaustion patterns:** CPU spikes usually clear on their own (depending on burstable instances like t3.micro); disk usage keeps climbing until you fix it manually or with automation.
- **Security groups:** A simple fix but one that can completely break an application.
- **Monitoring runs on its own layer:** The app can be fine even if CloudWatch Agent dies, but you'll be missing important data.
- **ASG recovery logic:** Knowing how to suspend auto-healing versus letting it replace instances saves time.

### Operational Lessons
- **Know your baseline:** You can't spot problems if you don't know what normal looks like.
- **Logs:** Error logs often contain the exact root cause if you know where to check.
- **Metrics narrow things down:** CloudWatch helps you see which instance or layer is acting up.
- **Process of elimination:** Ruling out healthy components is faster than chasing random theories.
- **Document during incidents:** Taking short notes while troubleshooting makes final reports easier and more accurate.

### AWS-Specific Knowledge
- **CloudWatch Agent vs. AWS metrics:** Know which data comes from AWS itself and which relies on the agent running.
- **Launch template versioning:** Having version history is helpful to compare changes. Important to note that existing instances won't update unless replaced with instance refresh or terminated.
- **User data execution:** Errors in user data can cause silent failures. Checking `/var/log/cloud-init-output.log` can lead to the root cause.
- **Target group health checks:** Can be healthy at EC2 level but unhealthy at ALB level.
- **RDS Security Group:** Database connections can be tricky, always check the simplest fix like security groups first.

## Repository Structure
```
aws-incident-response-lab/
├── README.md                           # This file
├── incidents/                          # Detailed incident reports
│   ├── 01-web-server-down.md
│   ├── 02-database-unreachable.md
│   ├── 03-high-cpu-usage.md
│   ├── 04-disk-space-alert.md
│   ├── 05-alb-502-errors.md
│   ├── 06-asg-launch-failure.md
│   └── 07-cloudwatch-agent-failure.md
├── runbooks/                           # Troubleshooting guide
│   └── troubleshooting.md
└── screenshots/                        # Evidence from investigations
    ├── 01-*.png
    ├── 02-*.png
    └── ...
```
## What I Learned & Can Do

Through this project, I gained hands-on experience operating and troubleshooting real AWS infrastructure. Each incident built on the last, helping me develop the skills needed for an operations role.

This project demonstrates my ability to:

**Run and maintain production-style systems** — EC2, RDS, ALB, and Auto Scaling Groups working together in a monitored environment.

**Troubleshoot complex issues** across layers (infrastructure, networking, application, and monitoring).

**Work through incidents methodically**, from detection to verification, while documenting each step.

**Design and refine monitoring systems** using CloudWatch metrics, alarms, and dashboards.

**Automate and validate configuration changes** through launch templates and user data scripts.

**Reflect on failures** and turn them into actionable improvements and prevention strategies.

These are real incidents I caused intentionally, investigated, and resolved using AWS services and Linux tools.

## Related Work

- **[aws-cloudwatch-monitoring](https://github.com/odysian/aws-cloudwatch-monitoring)** - The infrastructure this project builds on (Week 1)

- **[aws-terraform-infrastructure](https://github.com/odysian/aws-terraform-infrastructure)** - Rebuilding this infrastructure with Terraform (Week 3, planned)

## Project Overview

Timeline: Week 2 of my AWS learning journey (November 2025)
Time Spent: ~15 hours total (infrastructure review, 7 incident simulations, documentation)
AWS Cost: $0 (Free Tier resources and credits only)

This lab taught me how to think like an operator, more than just how to deploy AWS resources, but how to keep them running when things go wrong.

---

