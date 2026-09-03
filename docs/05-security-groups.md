# Security Groups

## 1. What is it?
A Security Group acts as a virtual firewall for your EC2 instances and AWS services to control inbound and outbound traffic. Unlike Network ACLs, Security Groups are stateful (inbound allowed traffic automatically permits return outbound traffic).

## 2. Why are we using it?
To implement least-privilege network security chaining across the 3 tiers.

## 3. Where does it fit in our architecture?
Attached to Elastic Network Interfaces (ENIs) of External ALB, Web EC2 nodes, Internal ALB, App EC2 nodes, and RDS database instance.

## 4. Architecture
```
Internet ---> [External-ALB-SG] ---> [Web-SG] ---> [Internal-ALB-SG] ---> [App-SG] ---> [DB-SG]
```

## 5. Configuration used in this project
| Security Group Name | Inbound Rules | Source / Security Group | Purpose |
| :--- | :--- | :--- | :--- |
| `External-ALB-SG` | HTTP (80), HTTPS (443) | `0.0.0.0/0` | Public internet entry |
| `Web-SG` | HTTP (80) | `External-ALB-SG` | Web server from External ALB only |
| `Internal-ALB-SG` | HTTP (80) | `Web-SG` | Internal ALB from Web tier only |
| `App-SG` | Custom TCP (8000) | `Internal-ALB-SG` | App Gunicorn from Internal ALB only |
| `DB-SG` | MySQL TCP (3306) | `App-SG` | RDS MySQL from App tier only |

## 6. Step-by-step implementation
1. VPC Dashboard -> Security Groups -> Create Security Group.
2. Create `External-ALB-SG` with inbound 80/443 from `0.0.0.0/0`.
3. Create `Web-SG` with inbound 80 referencing `External-ALB-SG`.
4. Create `Internal-ALB-SG` with inbound 80 referencing `Web-SG`.
5. Create `App-SG` with inbound 8000 referencing `Internal-ALB-SG`.
6. Create `DB-SG` with inbound 3306 referencing `App-SG`.

## 7. How it communicates with other components
Filters packets at the ENI level using dynamic stateful rules.

## 8. Security configuration
- **Zero hardcoded IP rules**: Security Group references are used exclusively for inter-tier communication.

## 9. Validation
```bash
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<YOUR_VPC_ID>"
```

## 10. Troubleshooting
- **Issue**: App tier connection to RDS fails with timeout.
- **Cause**: `DB-SG` does not list `App-SG` as an allowed source on port 3306.
- **Fix**: Update `DB-SG` inbound rule to reference `App-SG` ID.

## 11. Common mistakes
- Allowing `0.0.0.0/0` inbound access on port 3306 for RDS database.
- Using hardcoded private IP addresses in security rules instead of SG IDs.

## 12. Production recommendations
- Regularly audit security groups using AWS Config or GuardDuty.

## 13. Related components
- ENI
- EC2
- RDS

## 14. What we learned
Referencing Security Group IDs instead of IP ranges makes network access resilient to Auto Scaling IP changes.
