# Amazon Route 53 DNS Configuration

## 1. What is it?
Amazon Route 53 is a highly available and scalable cloud Domain Name System (DNS) web service designed to route end-user requests to internet applications running on AWS.

## 2. Why are we using it?
To map user-friendly domain queries (`adhithyan.dpdns.org`) directly to the dynamic endpoints of our External Application Load Balancer.

## 3. Where does it fit in our architecture?
Sits at the very front of our entry workflow, resolving client DNS lookups to the External ALB.

## 4. Architecture
```
User Browser ---> DNS Lookup (adhithyan.dpdns.org) ---> Route 53 Hosted Zone ---> Alias A Record ---> External ALB DNS
```

## 5. Configuration used in this project
- **Domain Name**: `adhithyan.dpdns.org`
- **Hosted Zone Type**: Public Hosted Zone
- **Record Type**: `A` Record (IPv4 Address)
- **Alias**: `Yes`
- **Alias Target**: `college-results-external-alb-233355692.us-east-2.elb.amazonaws.com`
- **Routing Policy**: Simple Routing

## 6. Step-by-step implementation
1. Route 53 -> Hosted Zones -> Create Hosted Zone.
2. Domain Name: `adhithyan.dpdns.org`, Type: Public Hosted Zone. Click **Create**.
3. Create Record -> Record Name: `adhithyan.dpdns.org`.
4. Record Type: `A - Routes traffic to an IPv4 address...`.
5. Enable **Alias** toggle.
6. Route traffic to: **Alias to Application and Classic Load Balancer**.
7. Region: `us-east-2`, Choose ALB: `college-results-external-alb`. Click **Create records**.

## 7. How it communicates with other components
Translates DNS requests into ALB IP addresses dynamically without requiring static IP binding.

## 8. Security configuration
- DNSSEC can be enabled on the hosted zone to protect against DNS spoofing attacks.

## 9. Validation
Query DNS resolution using `dig` or `nslookup`:
```bash
dig NS adhithyan.dpdns.org
dig A adhithyan.dpdns.org +short
```
Expected output: Returns the dynamic IP addresses of the External ALB.

## 10. Troubleshooting
- **Issue**: Domain fails to resolve externally.
- **Cause**: Domain registrar NS (Name Server) records do not match Route 53 hosted zone delegation NS records.
- **Fix**: Copy the 4 NS records from Route 53 hosted zone and update your domain registrar settings.

## 11. Common mistakes
- Creating a standard `CNAME` or `A` record with a hardcoded ALB IP address instead of using an **Alias A Record**.

## 12. Production recommendations
- Implement Route 53 Health Checks and Failover routing policies for multi-region disaster recovery.

## 13. Related components
- External ALB
- ACM SSL Certificate

## 14. What we learned
Alias A records seamlessly tracking ALB endpoint changes are superior to static IP assignments.
