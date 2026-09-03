# Internet Gateway (IGW)

## 1. What is it?
An Internet Gateway (IGW) is a horizontally scaled, redundant, and highly available VPC component that allows communication between instances in your VPC and the internet.

## 2. Why are we using it?
To enable inbound HTTP/HTTPS traffic from public web clients to our External Load Balancer and allow public web servers to send response packets back to users.

## 3. Where does it fit in our architecture?
Attached to the edge of `college-results-prod-vpc`, providing internet ingress/egress for the two public web subnets (`Public-Web-2a` and `Public-Web-2b`).

## 4. Architecture
```
Internet (0.0.0.0/0) <---> Internet Gateway <---> Public Route Table <---> Public Subnets (2a/2b)
```

## 5. Configuration used in this project
- **Name**: `college-results-prod-igw`
- **Attachment**: Attached to `college-results-prod-vpc` (`vpc-055fa55392fac0181`)
- **State**: `available` / `attached`

## 6. Step-by-step implementation
1. Navigate to AWS Console -> VPC -> Internet Gateways -> Create Internet Gateway.
2. Set Name tag to `college-results-prod-igw` and click **Create Internet Gateway**.
3. Select the created IGW -> Actions -> **Attach to VPC**.
4. Select `college-results-prod-vpc` and click **Attach Internet Gateway**.

## 7. How it communicates with other components
The IGW maps public IPv4 addresses assigned to AWS resources (or Elastic IPs attached to ALB/NAT) to their private IPv4 addresses within the public subnets via NAT logic built into the AWS network fabric.

## 8. Security configuration
- The IGW itself is managed by AWS and requires no security groups.
- Access through IGW is filtered by Security Groups and Network ACLs attached to instances/ALBs.

## 9. Validation
```bash
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<YOUR_VPC_ID>"
```
Expected output: State `attached`.

## 10. Troubleshooting
- **Issue**: Public EC2 instance cannot access internet despite having a public IP.
- **Cause**: IGW created but not attached to the VPC, or missing `0.0.0.0/0 -> igw-xxx` route in public route table.
- **Fix**: Attach IGW to VPC and verify public route table target.

## 11. Common mistakes
- Creating multiple IGWs for a single VPC (AWS supports only one IGW per VPC).
- Forgetting to attach the IGW to the target VPC.

## 12. Production recommendations
- Ensure AWS CloudTrail monitors IGW attachment/detachment actions.

## 13. Related components
- Public Route Table
- Elastic IP
- External Application Load Balancer

## 14. What we learned
An IGW alone does not grant internet access until explicit routes are added to subnet route tables.
