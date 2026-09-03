# Amazon CloudWatch Metrics & Logging

## 1. What is it?
Amazon CloudWatch is a monitoring and management service that provides data and actionable insights for AWS hybrid and cloud resources.

## 2. Why are we using it?
To monitor compute health, track active database connections, evaluate load balancer request latencies, collect system logs, and trigger alerts upon performance degradation.

## 3. Where does it fit in our architecture?
Collects telemetry, metrics, and log streams from EC2 instances, Auto Scaling Groups, Load Balancers, and RDS across the entire VPC.

## 4. Architecture
```
[EC2 Web/App] [ALBs] [RDS MySQL] ---> CloudWatch Metrics & Log Groups ---> Alarms & Dashboards
```

## 5. Configuration used in this project
### Key Monitored Metrics
- **EC2**: `CPUUtilization`, `StatusCheckFailed`
- **ALB**: `HealthyHostCount`, `UnHealthyHostCount`, `TargetResponseTime`, `HTTPCode_ELB_5XX_Count`
- **RDS**: `CPUUtilization`, `DatabaseConnections`, `FreeStorageSpace`

### Log Groups
- `/var/log/cloud-init-output.log` (Instance bootstrap logs)
- `/var/log/college-results-startup.log` (App startup logs)
- `/var/log/nginx/error.log` (Web proxy logs)

## 6. Step-by-step implementation
1. CloudWatch -> Alarms -> Create Alarm.
2. Select Metric -> EC2 -> Per-Instance Metrics -> `CPUUtilization`.
3. Threshold: Greater than `80%` for 2 consecutive periods of 5 minutes.
4. Configure Notification: Send to SNS Topic `admin-alerts`. Click **Create Alarm**.

## 7. How it communicates with other components
AWS hypervisors and service endpoints natively stream metrics to CloudWatch every 1-5 minutes.

## 8. Security configuration
- Ensure IAM policies grant least privilege (`CloudWatchLogsFullAccess` avoided; restricted to explicit log groups).

## 9. Validation
```bash
aws cloudwatch list-metrics --namespace "AWS/ApplicationELB"
aws cloudwatch get-metric-statistics --namespace "AWS/EC2" --metric-name "CPUUtilization" --dimensions Name=InstanceId,Value=<YOUR_INSTANCE_ID> --start-time 2026-09-02T00:00:00Z --end-time 2026-09-03T00:00:00Z --period 300 --statistics Average
```

## 10. Troubleshooting
- **Issue**: CloudWatch logs from custom application log files are not appearing.
- **Cause**: AWS CloudWatch Unified Agent is not installed or configured on the EC2 instances.
- **Fix**: Install `amazon-cloudwatch-agent` via User Data and supply `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`.

## 11. Common mistakes
- Ignoring `UnHealthyHostCount` metric alarms leading to undetected backend downtime.

## 12. Production recommendations
- Build a centralized CloudWatch Dashboard displaying real-time traffic request rates, 5xx error percentages, and RDS storage capacity.

## 13. Related components
- EC2
- Application Load Balancers
- Amazon RDS

## 14. What we learned
Proactive monitoring via CloudWatch alarms prevents silent outages before end-users report failures.
