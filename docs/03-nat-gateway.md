# NAT Gateway

## 1. What is it?
A Network Address Translation (NAT) Gateway is a managed AWS service that enables instances in a private subnet to connect to the internet or other AWS services, but prevents the internet from initiating a connection with those instances.

## 2. Why are we using it?
App EC2 instances in private subnets need outbound internet access to download OS security updates, clone application source code repositories (`github.com/ADHI18S/temp.git`), and install Python packages via `pip`.

## 3. Where does it fit in our architecture?
Located in `Public-Web-2a` subnet. Private application subnets route outbound traffic through this NAT Gateway.

## 4. Architecture
```
Private App EC2 (10.0.3.X) ---> Private App RT ---> NAT Gateway (Public-Web-2a) ---> IGW ---> Internet
```

## 5. Configuration used in this project
- **Name**: `college-results-prod-nat`
- **Subnet Placement**: `Public-Web-2a` (`10.0.1.0/24`)
- **Connectivity Type**: `Public`
- **Elastic IP**: Allocated and attached (`eipalloc-xxxx`)
- **Cost Optimization**: Single NAT Gateway deployed for training/demo cost efficiency.

## 6. Step-by-step implementation
1. VPC Dashboard -> NAT Gateways -> Create NAT Gateway.
2. Name: `college-results-prod-nat`.
3. Select Subnet: `Public-Web-2a`.
4. Click **Allocate Elastic IP** to attach a public static IP.
5. Click **Create NAT Gateway**.

## 7. How it communicates with other components
Receives traffic from Private App Route Table (`0.0.0.0/0 -> nat-xxx`), translates private source IP (`10.0.3.X`) to the Elastic IP address, forwards packets through IGW, and routes return packets back to the originating private EC2 instance.

## 8. Security configuration
- Completely blocks inbound internet connections to private application servers.

## 9. Validation
```bash
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<YOUR_VPC_ID>"
```
Log into a private App EC2 node via SSM Session Manager and test internet connectivity:
```bash
curl -I https://github.com
```

## 10. Troubleshooting
- **Issue**: `git clone` or `apt-get update` hangs indefinitely on private App EC2 instances.
- **Cause**: NAT Gateway state is `deleting` or private route table lacks `0.0.0.0/0 -> nat-xxx`.
- **Fix**: Verify NAT Gateway status is `available` and route table is correctly associated.

## 11. Common mistakes
- Deploying NAT Gateway in a private subnet instead of a public subnet.
- Forgetting to assign an Elastic IP during creation.

## 12. Production recommendations
- Deploy dual NAT Gateways across two AZs (`Public-Web-2a` and `Public-Web-2b`) for multi-AZ fault tolerance.

## 13. Related components
- Elastic IP
- Private App Route Table
- Internet Gateway

## 14. What we learned
NAT Gateways provide unidirectional outbound connectivity, essential for bootstrapping private EC2 workloads securely.
