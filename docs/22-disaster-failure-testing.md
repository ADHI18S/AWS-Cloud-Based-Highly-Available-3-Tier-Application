# Disaster & Failure Recovery Testing

## 1. Overview
To prove high availability and fault tolerance, six destructive chaos experiments were executed against the running production cluster.

---

## 2. Test Cases & Validation Results

### Experiment 1: Web EC2 Instance Termination
- **Action**: Manually terminated Web EC2 instance in `Public-Web-2a` via AWS Console.
- **Observation**: External ALB detected target failure within 30 seconds and routed 100% of web traffic to `Public-Web-2b`. Web ASG detected missing instance and launched replacement node.
- **User Impact**: ZERO user downtime or error pages experienced.

---

### Experiment 2: App EC2 Instance Termination
- **Action**: Terminated App EC2 instance in `Private-App-2a`.
- **Observation**: Internal ALB rerouted API requests to `Private-App-2b`. App ASG launched replacement instance, executed User Data bootstrap, and re-registered target.
- **User Impact**: ZERO API downtime.

---

### Experiment 3: Stopping NGINX Web Service
- **Action**: Logged into Web EC2 via SSM and executed `sudo systemctl stop nginx`.
- **Observation**: Target group health check failed on `/health`. Target state changed to `unhealthy`. ALB stopped sending traffic to node.
- **User Impact**: Traffic cleanly handled by second Web EC2 node.

---

### Experiment 4: Killing Gunicorn Process on App Server
- **Action**: Logged into App EC2 via SSM and executed `pkill -9 gunicorn`.
- **Observation**: `college-results.service` systemd unit automatically restarted Gunicorn within 5 seconds.
- **User Impact**: Temporary 1-second delay, system self-healed automatically.

---

### Experiment 5: Simulating RDS Database Failover
- **Action**: Initiated RDS Reboot with Failover via Console.
- **Observation**: Primary DB failed over from `us-east-2b` to standby in `us-east-2a`. Flask PyMySQL ping reconnect logic automatically re-established connection once DNS pointed to new primary.
- **User Impact**: Brief database reconnect window (<60 seconds), followed by complete recovery.

---

### Experiment 6: Simulating Single Availability Zone Outage
- **Action**: Simulated `us-east-2a` blackout by blocking traffic via Network ACL.
- **Observation**: ALBs and ASGs shifted entire application workload to `us-east-2b`.
- **User Impact**: System remained 100% operational on remaining AZ.
