# Target Groups & Health Checks

## 1. What is it?
A Target Group tells a load balancer where to route traffic (e.g., EC2 instances, IP addresses, Lambda functions) and defines the health check criteria to monitor target availability.

## 2. Why are we using it?
To group EC2 instances per tier (Web and App) and dynamically route traffic only to instances confirmed healthy.

## 3. Where does it fit in our architecture?
- `college-results-web-tg`: Registered with External ALB to receive Web traffic.
- `college-results-app-tg`: Registered with Internal ALB to receive App traffic.

## 4. Architecture
```
External ALB ---> Web Target Group (Port 80, Path /health)   ---> Web ASG EC2 Nodes
Internal ALB ---> App Target Group (Port 8000, Path /health) ---> App ASG EC2 Nodes
```

## 5. Configuration used in this project
### Web Target Group (`college-results-web-tg`)
- **Target Type**: `Instance`
- **Protocol / Port**: `HTTP` / `80`
- **VPC**: `college-results-prod-vpc`
- **Health Check Protocol**: `HTTP`
- **Health Check Path**: `/health`
- **Healthy Threshold**: `2`
- **Unhealthy Threshold**: `2`
- **Timeout**: `5 seconds`
- **Interval**: `30 seconds`
- **Success Codes**: `200`

### App Target Group (`college-results-app-tg`)
- **Target Type**: `Instance`
- **Protocol / Port**: `HTTP` / `8000`
- **VPC**: `college-results-prod-vpc`
- **Health Check Protocol**: `HTTP`
- **Health Check Path**: `/health`
- **Healthy Threshold**: `2`
- **Unhealthy Threshold**: `3`
- **Timeout**: `5 seconds`
- **Interval**: `30 seconds`
- **Success Codes**: `200`

## 6. Step-by-step implementation
1. EC2 -> Target Groups -> Create Target Group.
2. Select **Instances**, name `college-results-web-tg`, set HTTP 80, VPC `college-results-prod-vpc`.
3. Set Health Check path to `/health`. Save.
4. Repeat for `college-results-app-tg` with HTTP 8000, path `/health`.

## 7. How it communicates with other components
ALBs continuously send background HTTP GET requests to `/health` on all registered targets. If a target fails to respond with `200 OK` within the threshold, it is marked `unhealthy` and removed from routing.

## 8. Security configuration
- Target Groups rely on the underlying instance Security Groups to permit health check probes.

## 9. Validation
```bash
aws elbv2 describe-target-health --target-group-arn <YOUR_TARGET_GROUP_ARN>
```
Expected TargetHealthState: `healthy`.

## 10. Troubleshooting
- **Issue**: Target status remains `initial` or becomes `unhealthy` with status `HTTP 503` or `Timeout`.
- **Cause**: Application not listening on the expected port, or health check path returns non-200 code.
- **Fix**: Check `curl http://127.0.0.1:<PORT>/health` locally on the EC2 instance.

## 11. Common mistakes
- Setting health check path to `/` when `/` requires database authentication or returns a redirect.
- Misconfiguring target port (e.g. configuring port 80 for App tier instead of 8000).

## 12. Production recommendations
- Implement custom health check logic verifying memory, disk space, and DB connection readiness.

## 13. Related components
- Application Load Balancers
- Auto Scaling Groups
- EC2 Instances

## 14. What we learned
Dedicated lightweight `/health` endpoints prevent false-positive target failures and ensure zero-downtime routing.
