# Auto Scaling Groups (ASG) & Self-Healing

## 1. What is it?
An Auto Scaling Group (ASG) contains a collection of Amazon EC2 instances that are treated as a logical grouping for automatic scaling, management, health monitoring, and dynamic capacity management across multiple Availability Zones.

## 2. Why are we using it?
To guarantee high availability, maintain minimum compute capacity, distribute instances across two Availability Zones (`us-east-2a` and `us-east-2b`), and automatically replace failed or unhealthy EC2 instances.

## 3. Where does it fit in our architecture?
- `college-results-web-asg`: Controls Web EC2 nodes in public subnets behind External ALB.
- `college-results-app-asg`: Controls App EC2 nodes in private subnets behind Internal ALB.

## 4. Architecture
```
Auto Scaling Group (Desired: 2, Min: 2, Max: 2)
├── us-east-2a Subnet ---> EC2 Instance 1 (Healthy)
└── us-east-2b Subnet ---> EC2 Instance 2 (Healthy)
     |
     v (Instance Terminated / Unhealthy)
Auto Scaling replaces instance automatically in same AZ!
```

## 5. Configuration used in this project
### Web Auto Scaling Group (`college-results-web-asg`)
- **Launch Template**: `college-results-web-lt` (Version 2)
- **VPC Subnets**: `Public-Web-2a`, `Public-Web-2b`
- **Desired Capacity**: `2`
- **Minimum Capacity**: `2`
- **Maximum Capacity**: `2`
- **Target Group**: `college-results-web-tg`
- **Health Check Type**: `ELB` (Grace Period: `300 seconds`)

### App Auto Scaling Group (`college-results-app-asg`)
- **Launch Template**: `college-results-app-lt` (Version 2)
- **VPC Subnets**: `Private-App-2a`, `Private-App-2b`
- **Desired Capacity**: `2`
- **Minimum Capacity**: `2`
- **Maximum Capacity**: `2`
- **Target Group**: `college-results-app-tg`
- **Health Check Type**: `ELB` (Grace Period: `300 seconds`)

## 6. Step-by-step implementation
1. EC2 -> Auto Scaling Groups -> Create Auto Scaling Group.
2. Name: `college-results-web-asg`, Launch Template: `college-results-web-lt`.
3. VPC: `college-results-prod-vpc`, Subnets: `Public-Web-2a` and `Public-Web-2b`.
4. Attach to an existing load balancer -> Target Group `college-results-web-tg`.
5. Enable ELB health checks with 300 second grace period.
6. Set Desired: 2, Min: 2, Max: 2. Click **Create Auto Scaling Group**.
7. Repeat for `college-results-app-asg` pointing to Private App subnets and `college-results-app-tg`.

## 7. How it communicates with other components
Monitors Target Group health statuses via ELB integrations. If a target is marked `unhealthy`, the ASG automatically terminates the failed instance and launches a fresh EC2 replacement using the configured Launch Template.

## 8. Security configuration
- Inherits security profiles, IAM instance profiles, and subnet boundaries specified in the attached Launch Templates.

## 9. Validation
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names college-results-web-asg college-results-app-asg
```
Verify instance health states:
```bash
aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[*].[InstanceId,AutoScalingGroupName,HealthStatus,LifecycleState]" --output table
```

## 10. Troubleshooting
- **Issue**: ASG repeatedly launches and terminates instances (Scaling Loop).
- **Cause**: User Data script failing or health check grace period expiring before application finishes initializing.
- **Fix**: Increase health check grace period to `300` seconds and fix User Data bootstrap errors.

## 11. Common mistakes
- Setting Health Check Type to `EC2` instead of `ELB` (EC2 check only detects hardware failure, ignoring application crashes).
- Restricting subnets to a single AZ, defeating multi-AZ fault tolerance.

## 12. Production recommendations
- Implement Target Tracking Scaling Policies based on CPU utilization (e.g. scale up when CPU > 70%).

## 13. Related components
- Launch Templates
- Target Groups
- EC2 Instances

## 14. What we learned
ELB health check integration ensures self-healing capacity replacement without human intervention.
