# AWS Incident Response Lab

## Project Status: In Progress

Building systematic troubleshooting skills through hands-on incident response scenarios.

## Overview
This project simulates real-world AWS production incidents to develop and demonstrate operational troubleshooting capabilities. Each incident includes:
- Intentional system failure
- Systematic investigation process
- Root cause analysis
- Resolution and verification
- Detailed incident documentation

## Infrastructure
Using existing multi-tier AWS environment from aws-cloudwatch-monitoring repo:
- VPC with multi-AZ subnets
- Application Load Balancer
- Auto Scaling Group (2-4 instances)
- RDS MySQL database
- CloudWatch monitoring and alarms

## [Incidents Completed](incidents)
- [x] #01: [Web Server Down](incidents/01-web-server-down.md)
- [x] #02: [Database Unreachable](incidents/02-database-unreachable.md)
- [x] #03: [High CPU Usage](incidents/03-high-cpu-usage.md)
- [x] #04: [Disk Full](incidents/04-disk-space-alert.md)
- [ ] #05: ALB 502 Errors
- [ ] #06: Auto Scaling Not Working

## Skills Demonstrated
- Systematic troubleshooting
- AWS service debugging (EC2, RDS, ALB, ASG)
- Linux system administration
- Incident documentation and reporting
- Root cause analysis

## Repository Structure
```
aws-incident-response-lab/
├── README.md
├── incidents/          # Individual incident reports
├── runbooks/           # Troubleshooting guides and methodology
├── scripts/            # Scripts to simulate failures
└── screenshots/        # Evidence of investigation and resolution
```

---