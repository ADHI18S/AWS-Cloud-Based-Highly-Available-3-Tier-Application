# High Availability & Fault Tolerance Strategy

## 1. Multi-AZ Compute Architecture
The web and application tiers are distributed evenly across two Availability Zones (`us-east-2a` and `us-east-2b`).

```
us-east-2a                             us-east-2b
├── Public-Web-2a (Web EC2 1)           ├── Public-Web-2b (Web EC2 2)
├── Private-App-2a (App EC2 1)           ├── Private-App-2b (App EC2 2)
└── Private-DB-2a (RDS Standby)          └── Private-DB-2b (RDS Primary)
```

## 2. Load Balancer Redundancy
Both External and Internal Application Load Balancers span multiple Availability Zones, automatically routing traffic away from degraded zones.

## 3. Amazon RDS Multi-AZ Failover
Amazon RDS automatically provisions a standby replica in `us-east-2a` while maintaining the active primary instance in `us-east-2b`. Synchronous block-level replication guarantees zero data loss during failure.
- In the event of primary DB hardware failure or AZ outage, RDS automatically updates DNS records to point to the standby instance within 60-120 seconds.

## 4. Auto Scaling Self-Healing
If an EC2 instance fails an ELB health check:
1. Target Group marks the instance `unhealthy`.
2. Load Balancer stops routing incoming requests to that instance.
3. Auto Scaling Group terminates the unhealthy instance.
4. Auto Scaling Group automatically launches a replacement EC2 instance in the same AZ using the active Launch Template.
