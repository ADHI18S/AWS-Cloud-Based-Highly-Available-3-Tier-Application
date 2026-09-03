# Security Architecture & Hardening Guidelines

## 1. Network Segmentation & Subnet Isolation
- Presentation (Web), Business Logic (App), and Data Persistence (RDS) reside in dedicated subnets.
- Database subnets have zero direct routes to the internet (no IGW, no NAT Gateway).

## 2. Least-Privilege Security Group Chaining
Inbound firewall permissions are restricted strictly to necessary ports from preceding architectural tiers:
- `Internet` -> `External ALB` (80/443)
- `External ALB` -> `Web EC2` (80)
- `Web EC2` -> `Internal ALB` (80)
- `Internal ALB` -> `App EC2` (8000)
- `App EC2` -> `RDS MySQL` (3306)

## 3. Elimination of Inbound SSH Ports
- Inbound TCP Port 22 is disabled across all Security Groups.
- Administration is conducted strictly via **AWS Systems Manager (SSM) Session Manager** authenticated via IAM.

## 4. Encryption Standards
- **Data in Transit**: Enforced TLS 1.2/1.3 encryption on public listener using ACM certificates. Internal traffic communicates across AWS isolated VPC ENIs.
- **Data at Rest**: Storage volume encryption enabled on Amazon RDS using KMS keys. EBS root volumes encrypted.

## 5. Zero Hardcoded Credentials
- No passwords, secret keys, or database endpoints are hardcoded in application repository files.
- Configuration parameters are injected dynamically via environment variables (`.env`).

## 6. Security Header Enforcement
NGINX applies production HTTP security headers to prevent cross-site scripting and frame injection:
```nginx
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
```
