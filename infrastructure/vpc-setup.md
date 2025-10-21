# 🏗️ VPC Setup and Network Configuration

This document describes the virtual private cloud (VPC) setup used for the 3-tier College Exam Result Website on AWS us-east-2.

---

## VPC Details

- **VPC CIDR:** 10.0.0.0/16
- **Region:** us-east-2 (Ohio)
- **DNS Hostnames:** Enabled
- **DNS Resolution:** Enabled

---

## Subnets

| Subnet Name   | Type    | CIDR         | AZ         | Purpose           |
|---------------|---------|--------------|------------|-------------------|
| Public-Web-2a | Public  | 10.0.1.0/24  | us-east-2a | Web tier          |
| Public-Web-2b | Public  | 10.0.2.0/24  | us-east-2b | Web tier          |
| Private-App-2a| Private | 10.0.3.0/24  | us-east-2a | Application tier  |
| Private-App-2b| Private | 10.0.4.0/24  | us-east-2b | Application tier  |
| Private-DB-2a | Private | 10.0.5.0/24  | us-east-2a | Database tier     |
| Private-DB-2b | Private | 10.0.6.0/24  | us-east-2b | Database tier     |

---

## Internet Gateways & NAT Gateways

- **Internet Gateway:** Attached to VPC for public subnet access
- **NAT Gateway:** In public subnet, provides outbound internet to private subnets

---

## Route Tables

**Public route table:**

- Main route: `10.0.0.0/16 → local`
- Internet route: `0.0.0.0/0 → Internet Gateway`
- Associated with public subnets

**Private route table:**

- Main route: `10.0.0.0/16 → local`
- Internet route: `0.0.0.0/0 → NAT Gateway`
- Associated with private subnets (app + db)

---

## Security Best Practices

- Use separate route tables for public/private subnets
- Attach Network ACLs as needed for additional security
- Enable Flow Logs for network monitoring

---

_Last updated: October 2025_
