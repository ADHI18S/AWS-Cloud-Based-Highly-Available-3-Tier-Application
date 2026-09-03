# AWS Certificate Manager (ACM) & HTTPS

## 1. What is it?
AWS Certificate Manager (ACM) is a service that lets you easily provision, manage, and deploy public and private Secure Sockets Layer/Transport Layer Security (SSL/TLS) certificates for use with AWS services.

## 2. Why are we using it?
To secure user communication with end-to-end encryption in transit (HTTPS/TLS 1.3), protect sensitive student examination requests, and establish trust.

## 3. Where does it fit in our architecture?
Attached to the port 443 HTTPS Listener on the External Application Load Balancer.

## 4. Architecture
```
User Browser (HTTPS 443) ---> External ALB (ACM Certificate Decryption) ---> Web Target Group (HTTP 80)
```

## 5. Configuration used in this project
- **Domain Name**: `adhithyan.dpdns.org`
- **Validation Method**: DNS Validation
- **Certificate Region**: `us-east-2` (Crucial: Must match ALB region!)
- **Status**: `Issued`
- **ALB Integration**: Attached to `college-results-external-alb` Port 443 Listener

## 6. Step-by-step implementation
1. AWS Certificate Manager -> Request Certificate -> Request a public certificate.
2. Fully qualified domain name: `adhithyan.dpdns.org`.
3. Validation method: **DNS validation**. Click **Request**.
4. Open requested certificate -> Click **Create records in Route 53** to automatically insert the CNAME validation record.
5. Wait 2-5 minutes for status to change from `Pending validation` to `Issued`.
6. Open EC2 -> Load Balancers -> `college-results-external-alb`.
7. Add Listener -> Protocol: HTTPS, Port: 443 -> Default Action: Forward to `college-results-web-tg`.
8. Attach default SSL Certificate: Select `adhithyan.dpdns.org`.
9. Edit Port 80 Listener -> Action: **Redirect to HTTPS 443** (HTTP Status Code 301).

## 7. How it communicates with other components
Decrypts incoming TLS traffic at the External ALB and forwards decrypted HTTP traffic to backend NGINX web servers over the AWS internal network.

## 8. Security configuration
- Enforces strong TLS 1.2 / 1.3 encryption protocols (`ELBSecurityPolicy-TLS13-1-2-2021-06`).

## 9. Validation
Test HTTPS connection and SSL certificate details via `curl`:
```bash
curl -I https://adhithyan.dpdns.org
```
Expected output: `HTTP/2 200` or `HTTP/1.1 200 OK` with valid SSL certificate handshake.

## 10. Troubleshooting
- **Issue**: ACM Certificate issued in `us-east-1` cannot be attached to ALB in `us-east-2`.
- **Cause**: ACM certificates are region-bound for ALBs (only CloudFront requires certificates in `us-east-1`).
- **Fix**: Re-request certificate explicitly in `us-east-2`.

## 11. Common mistakes
- Forgetting to configure HTTP (Port 80) to HTTPS (Port 443) redirection on the load balancer.

## 12. Production recommendations
- ACM handles automated 13-month certificate renewals; ensure DNS CNAME validation records remain untouched in Route 53.

## 13. Related components
- External ALB
- Route 53

## 14. What we learned
Offloading SSL decryption at the ALB eliminates CPU cryptographic overhead on backend web instances.
