# Internal Application Load Balancer

## 1. What is it?
An Internal Application Load Balancer (ALB) routes HTTP/HTTPS requests to targets (such as EC2 instances) using private IP addresses within your VPC.

## 2. Why are we using it?
To load balance backend API requests across multiple Application EC2 instances in private subnets, enabling seamless scaling and fault tolerance without exposing the App tier to the public internet.

## 3. Where does it fit in our architecture?
Deployed across `Private-App-2a` and `Private-App-2b`. It accepts traffic from NGINX Web nodes on port 80 and forwards requests to App EC2 nodes on port 8000.

## 4. Architecture
```
Web EC2 (Public Subnets) ---> Internal ALB DNS (Private App Subnets) ---> App Target Group :8000 ---> App EC2 (2a/2b)
```

## 5. Configuration used in this project
- **Name**: `college-results-internal-alb`
- **Scheme**: `Internal`
- **IP Address Type**: `IPv4`
- **Subnets**: `Private-App-2a` (`10.0.3.0/24`), `Private-App-2b` (`10.0.4.0/24`)
- **Security Group**: `Internal-ALB-SG` (Allows HTTP 80 from `Web-SG` only)
- **Listener**: HTTP Port 80 -> Forward to `college-results-app-tg`
- **DNS Name**: `internal-college-results-internal-alb-499729443.us-east-2.elb.amazonaws.com`

## 6. Step-by-step implementation
1. EC2 -> Load Balancers -> Create Load Balancer -> Application Load Balancer.
2. Name: `college-results-internal-alb`, Scheme: **Internal**.
3. VPC: `college-results-prod-vpc`, Subnets: Select `Private-App-2a` and `Private-App-2b`.
4. Security Group: Select `Internal-ALB-SG`.
5. Listener: HTTP 80 -> Action: Forward to Target Group `college-results-app-tg`.
6. Click **Create Load Balancer**.

## 7. How it communicates with other components
Receives HTTP requests sent to its private DNS name by NGINX web servers. Performs round-robin distribution across healthy targets registered in `college-results-app-tg`.

## 8. Security configuration
- Private scheme prevents external internet endpoints from reaching the ALB.
- Inbound access allowed exclusively on port 80 from `Web-SG`.

## 9. Validation
From a Web EC2 instance, execute:
```bash
curl http://internal-college-results-internal-alb-499729443.us-east-2.elb.amazonaws.com/health
```
Expected output: `{"database":"connected","status":"healthy"}`.

> 📸 Screenshot: Load Balancers Console
> ![Load Balancers](images/load-balancers.png)

## 10. Troubleshooting
- **Issue**: Internal ALB health checks fail and show `unhealthy` targets.
- **Cause**: Security Group `App-SG` is blocking port 8000 traffic originating from `Internal-ALB-SG`.
- **Fix**: Update `App-SG` inbound rules to allow port 8000 from `Internal-ALB-SG`.

## 11. Common mistakes
- Selecting public subnets for an internal load balancer.
- Failing to enable cross-AZ load balancing when targets are unevenly distributed.

## 12. Production recommendations
- Enable HTTP/2 and gRPC protocol support if upgrading microservice communication.

## 13. Related components
- App Target Group
- Web EC2 (NGINX)
- App Security Group

## 14. What we learned
Internal load balancers provide an elegant microservice boundary, hiding backend scaling complexity from presentation servers.
