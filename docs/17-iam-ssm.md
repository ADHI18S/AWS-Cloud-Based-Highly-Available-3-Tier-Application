# AWS IAM & Systems Manager (SSM) Session Manager

## 1. What is it?
AWS Identity and Access Management (IAM) manages secure access to AWS services. AWS Systems Manager (SSM) Session Manager provides secure, auditable, shell-based instance management without opening inbound SSH ports or managing SSH keys.

## 2. Why are we using it?
To grant EC2 instances permissions to access AWS services safely and permit administrators to log into private App and Web servers without exposing port 22 to the internet.

## 3. Where does it fit in our architecture?
Attached as an IAM Instance Profile (`college-results-app-ssm-role`) to all Web and App EC2 instances.

## 4. Architecture
```
Admin Browser / AWS CLI ---> AWS SSM Service ---> SSM Agent (EC2 Private Subnet) ---> Secure Shell Access
```

## 5. Configuration used in this project
- **IAM Role Name**: `college-results-app-ssm-role`
- **Trusted Entity**: `ec2.amazonaws.com`
- **Managed Policy Attached**: `AmazonSSMManagedInstanceCore`
- **Instance Profile**: `college-results-app-ssm-role` attached to EC2 Launch Templates

## 6. Step-by-step implementation
1. IAM Console -> Roles -> Create Role.
2. Trusted entity type: **AWS service** -> Use case: **EC2**.
3. Attach policy: `AmazonSSMManagedInstanceCore`.
4. Role Name: `college-results-app-ssm-role`. Click **Create Role**.
5. Attach instance profile to EC2 Launch Templates.

## 7. How it communicates with other components
The background `amazon-ssm-agent` daemon on Ubuntu EC2 establishes outbound HTTPS connections to the AWS Systems Manager endpoint over the NAT Gateway.

## 8. Security configuration
- **Port 22 SSH disabled**: Eliminates brute-force SSH attacks and key management overhead.
- All session commands logged to CloudWatch or S3 for audit compliance.

## 9. Validation
Log into a private instance via AWS CLI:
```bash
aws ssm start-session --target <YOUR_INSTANCE_ID>
```
Expected output: Opens an interactive terminal shell as `ssm-user`.

## 10. Troubleshooting
- **Issue**: Instance does not appear in Systems Manager Managed Instances list.
- **Cause**: Outbound HTTPS connectivity to SSM endpoints failing, or IAM instance profile missing `AmazonSSMManagedInstanceCore`.
- **Fix**: Check NAT Gateway routing and confirm instance profile assignment.

## 11. Common mistakes
- Attaching policy directly to IAM Users instead of creating an IAM Role for EC2 instances.

## 12. Production recommendations
- Enforce MFA for all console users initiating SSM Session Manager connections.

## 13. Related components
- IAM Instance Profiles
- EC2 User Data
- Systems Manager Agent

## 14. What we learned
SSM Session Manager completely obsoletes bastion hosts and public SSH key management in modern cloud architectures.
