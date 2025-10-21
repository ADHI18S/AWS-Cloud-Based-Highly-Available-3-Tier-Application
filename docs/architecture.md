#  Architecture Documentation

This document explains the 3-tier AWS architecture of the College Exam Result Website.

![3-tier architecture on AWS](<3 trier  (1).png>)

## Overview

- **Web Tier:** NGINX servers on EC2 in public subnets, deployed to 2 AZs with an external ALB.
- **Application Tier:** Flask API servers on EC2 in private subnets, deployed to 2 AZs with an internal ALB.
- **Database Tier:** Multi-AZ Amazon RDS MySQL database in private subnets.

## Design Details

- VPC with CIDR 10.0.0.0/16 in us-east-2 region
- Public subnets for web tier, private subnets for app and database tiers
- Internet Gateway attached for public subnet internet access
- NAT Gateway for private subnet outbound connectivity
- Security groups restrict access between tiers for security
- Load balancers distribute traffic and provide fault tolerance
- Auto Scaling Groups provide dynamic scaling based on CPU load
- RDS Multi-AZ ensures database availability and failover

## Diagram

See project root README or image in docs for detailed visual.

---

## Benefits

- High availability across AZs
- Scalability with Auto Scaling
- Strong network isolation and security
- Easy management and maintenance

---

Last updated: October 2025
