# External Application Load Balancer

## 1. What is it?
An Internet-Facing Application Load Balancer (ALB) sits at the perimeter of your AWS architecture, accepting public traffic from the internet and distributing it across public targets.

## 2. Why are we using it?
To serve as the entry point for all student and public browser traffic, offering high availability, SSL termination, and protection for Web EC2 nodes.

## 3. Where does it fit in our architecture?
Deployed across public subnets `Public-Web-2a` and `Public-Web-2b`. Accepts HTTPS (443) and HTTP (80) traffic from the internet and forwards requests to `college-results-web-tg`.

## 4. Architecture
```
User Browser (Internet) ---> Route 53 ---> External ALB :443/:80 ---> Web Target Group :80 ---> NGINX Web EC2 (2a/2b)
```

## 5. Configuration used in this project
- **Name**: `college-results-external-alb`
- **Scheme**: `Internet-facing`
- **IP Address Type**: `IPv4`
- **Subnets**: `Public-Web-2a` (`10.0.1.0/24`), `Public-Web-2b` (`10.0.2.0/24`)
- **Security Group**: `External-ALB-SG` (Allows HTTP 80 & HTTPS 443 from `0.0.0.0/0`)
- **Listeners**:
  - HTTP Port 80 -> Redirect to HTTPS 443 (or Forward to `college-results-web-tg` in HTTP mode)
  - HTTPS Port 443 -> Certificate `adhithyan.dpdns.org` -> Forward to `college-results-web-tg`

## 6. Step-by-step implementation
1. EC2 -> Load Balancers -> Create Load Balancer -> Application Load Balancer.
2. Name: `college-results-external-alb`, Scheme: **Internet-facing**.
3. Select VPC `college-results-prod-vpc` and Public Subnets `Public-Web-2a` & `Public-Web-2b`.
4. Security Group: Select `External-ALB-SG`.
5. Listener 80 & 443 -> Target Group `college-results-web-tg`.
6. Attach ACM SSL Certificate to port 443 listener.

## 7. How it communicates with other components
Receives public internet requests, evaluates listener rules, offloads SSL decryption, and balances requests across registered Web EC2 instances over port 80.

## 8. Security configuration
- Protected by `External-ALB-SG`.
- Enforces modern TLS security policies (`ELBSecurityPolicy-TLS13-1-2-2021-06`).

## 9. Validation
```bash
curl -I http://college-results-external-alb-233355692.us-east-2.elb.amazonaws.com/health
```
Expected response: `HTTP/1.1 200 OK`.

## 10. Troubleshooting
- **Issue**: External ALB returns `502 Bad Gateway`.
- **Cause**: Web Target Group instances are failing health checks or `Web-SG` is blocking traffic from `External-ALB-SG`.
- **Fix**: Verify Web EC2 NGINX service status and security group ingress rules.

## 11. Common mistakes
- Deploying an Internet-facing ALB in private subnets.
- Missing route `0.0.0.0/0 -> IGW` in public subnet route table.

## 12. Production recommendations
- Attach AWS WAF (Web Application Firewall) to block common web exploits.

## 13. Related components
- Route 53
- ACM SSL Certificate
- Web Target Group

## 14. What we learned
External load balancers protect web servers by offloading SSL certificates and absorbing traffic spikes.
