# Amazon VPC Networking & Subnets

## 1. What is it?
Amazon Virtual Private Cloud (VPC) is a logically isolated virtual network dedicated to your AWS account. It gives you complete control over your virtual networking environment, including selection of your own IP address range, creation of subnets, and configuration of route tables and network gateways.

## 2. Why are we using it?
To establish a secure, multi-tier network perimeter for our 3-tier College Exam Result application. It enables strict isolation between public-facing web components, private application logic, and confidential student database records.

## 3. Where does it fit in our architecture?
The VPC acts as the container for all network resources in `us-east-2`. It spans two Availability Zones (`us-east-2a` and `us-east-2b`) and encompasses six distinct subnets divided across three tiers (Web, App, DB).

## 4. Architecture
```
VPC: college-results-prod-vpc (10.0.0.0/16)
├── us-east-2a
│   ├── Public-Web-2a   (10.0.1.0/24)
│   ├── Private-App-2a  (10.0.3.0/24)
│   └── Private-DB-2a   (10.0.5.0/24)
└── us-east-2b
    ├── Public-Web-2b   (10.0.2.0/24)
    ├── Private-App-2b  (10.0.4.0/24)
    └── Private-DB-2b   (10.0.6.0/24)
```

## 5. Configuration used in this project
- **VPC Name**: `college-results-prod-vpc`
- **IPv4 CIDR Block**: `10.0.0.0/16`
- **DNS Resolution**: Enabled (`enableDnsHostnames = true`, `enableDnsSupport = true`)
- **Region**: `us-east-2`

### Subnet Layout
| Subnet Name | CIDR Block | AZ | Route Table | Auto-assign Public IP |
| :--- | :--- | :--- | :--- | :--- |
| `Public-Web-2a` | `10.0.1.0/24` | `us-east-2a` | Public Route Table | Yes |
| `Public-Web-2b` | `10.0.2.0/24` | `us-east-2b` | Public Route Table | Yes |
| `Private-App-2a` | `10.0.3.0/24` | `us-east-2a` | Private App Route Table | No |
| `Private-App-2b` | `10.0.4.0/24` | `us-east-2b` | Private App Route Table | No |
| `Private-DB-2a` | `10.0.5.0/24` | `us-east-2a` | Private DB Route Table | No |
| `Private-DB-2b` | `10.0.6.0/24` | `us-east-2b` | Private DB Route Table | No |

## 6. Step-by-step implementation
1. Open AWS Management Console -> VPC -> Create VPC.
2. Select **VPC and more**, name it `college-results-prod-vpc`, and set IPv4 CIDR to `10.0.0.0/16`.
3. Choose 2 Availability Zones (`us-east-2a`, `us-east-2b`).
4. Configure 2 Public subnets, 2 Private application subnets, and 2 Private database subnets.
5. Click **Create VPC**.

## 7. How it communicates with other components
Subnets within the same VPC communicate via local routing using the default local route (`10.0.0.0/16 -> local`). Cross-tier communication is restricted by Security Groups attached to resource interfaces.

## 8. Security configuration
- Private subnets do not assign public IPv4 addresses.
- Database subnets are strictly isolated without any route to NAT Gateways or Internet Gateways.

## 9. Validation
Run AWS CLI commands to verify VPC and subnet configuration:
```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=college-results-prod-vpc"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<YOUR_VPC_ID>" --query "Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key=='Name'].Value|[0]]" --output table
```

> 📸 Screenshot: VPC Resource Map
> ![VPC Resource Map](images/vpc-resource-map.png)

## 10. Troubleshooting
- **Issue**: Instances in private subnets cannot access internal services.
- **Cause**: Overlapping CIDR ranges or missing local VPC route.
- **Fix**: Ensure all subnet CIDR ranges fall within `10.0.0.0/16` without overlapping.

## 11. Common mistakes
- Placing RDS database instances in public subnets with public IP addresses enabled.
- Selecting a small CIDR block (e.g. `/28`) limiting IP addresses for Auto Scaling.

## 12. Production recommendations
- Reserve extra subnet IP space for containerization/EKS upgrades.
- Enable VPC Flow Logs streamed to CloudWatch for network auditing.

## 13. Related components
- Internet Gateway
- NAT Gateway
- Route Tables

## 14. What we learned
Proper IP address planning and subnet isolation form the foundational security layer of enterprise cloud architectures.
