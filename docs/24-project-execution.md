# Master Project Execution & Deployment Guide

## 1. Executive Summary
This document provides the complete 20-phase, step-by-step master execution guide for deploying the 3-Tier College Exam Result Website on AWS from scratch in an empty AWS account.

---

## 2. Phase-by-Phase Master Execution

### Phase 1: Create VPC & Subnets
1. VPC Console -> Create VPC -> **VPC and More**.
2. Name: `college-results-prod-vpc`, IPv4 CIDR: `10.0.0.0/16`.
3. 2 Availability Zones (`us-east-2a`, `us-east-2b`).
4. 2 Public Subnets (`10.0.1.0/24`, `10.0.2.0/24`).
5. 2 Private App Subnets (`10.0.3.0/24`, `10.0.4.0/24`).
6. 2 Private DB Subnets (`10.0.5.0/24`, `10.0.6.0/24`).

### Phase 2: Attach Internet Gateway
1. Internet Gateways -> Create `college-results-prod-igw`.
2. Attach to `college-results-prod-vpc`.

### Phase 3: Create NAT Gateway
1. NAT Gateways -> Create `college-results-prod-nat` in `Public-Web-2a`.
2. Allocate Elastic IP and attach.

### Phase 4: Configure Route Tables
1. Public Route Table (`college-results-prod-public-rt`): Add `0.0.0.0/0 -> IGW`. Associate Public subnets.
2. Private App Route Table (`college-results-prod-private-app-rt`): Add `0.0.0.0/0 -> NAT`. Associate Private App subnets.
3. Private DB Route Table (`college-results-prod-private-db-rt`): Local route only. Associate Private DB subnets.

### Phase 5: Security Groups Creation
1. Create `External-ALB-SG`: Inbound 80/443 from `0.0.0.0/0`.
2. Create `Web-SG`: Inbound 80 from `External-ALB-SG`.
3. Create `Internal-ALB-SG`: Inbound 80 from `Web-SG`.
4. Create `App-SG`: Inbound 8000 from `Internal-ALB-SG`.
5. Create `DB-SG`: Inbound 3306 from `App-SG`.

### Phase 6: Provision RDS MySQL Database
1. Create DB Subnet Group with `Private-DB-2a` and `Private-DB-2b`.
2. Provision RDS MySQL 8.0 `college-results-db` in Multi-AZ mode with `DB-SG`.
3. Import `database_schema.sql`.

### Phase 7: Create IAM Role for SSM
1. Create IAM Role `college-results-app-ssm-role` with policy `AmazonSSMManagedInstanceCore`.

### Phase 8: Provision Internal ALB & Target Group
1. Create Target Group `college-results-app-tg` (HTTP 8000, Path `/health`).
2. Create Internal ALB `college-results-internal-alb` in private app subnets.

### Phase 9: Launch Application Tier ASG
1. Create Launch Template `college-results-app-lt` with `App-SG`, IAM Role, and `backend-launch-temp.sh` User Data.
2. Create ASG `college-results-app-asg` (Min: 2, Desired: 2, Max: 2).

### Phase 10: Provision External ALB & Target Group
1. Create Target Group `college-results-web-tg` (HTTP 80, Path `/health`).
2. Create External ALB `college-results-external-alb` in public subnets with `External-ALB-SG`.

### Phase 11: Launch Web Tier ASG
1. Create Launch Template `college-results-web-lt` with `Web-SG` and `frontend-launch-temp.sh` User Data.
2. Create ASG `college-results-web-asg` (Min: 2, Desired: 2, Max: 2).

### Phase 12: Route 53 & SSL Setup
1. Request ACM Certificate for `adhithyan.dpdns.org` in `us-east-2`. Validate via Route 53.
2. Create Route 53 Alias A record pointing `adhithyan.dpdns.org` to External ALB.
3. Attach ACM certificate to HTTPS 443 Listener on External ALB. Redirect HTTP to HTTPS.

### Phase 13: Final Validation
1. Verify target health states across Web and App Target Groups (`healthy`).
2. Open `https://adhithyan.dpdns.org` in browser and query student result.
3. Verify successful data rendering from RDS MySQL database.
