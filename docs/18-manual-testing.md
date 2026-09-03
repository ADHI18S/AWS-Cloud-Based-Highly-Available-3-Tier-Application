# Comprehensive Manual Testing Checklist

## 1. Overview
This document details the step-by-step validation procedures executed to verify every layer of the 3-Tier College Exam Result Website architecture prior to Terraform automation.

## 2. Testing Phase Matrix

### Phase 1: Network & Security Group Verification
```bash
# Verify VPC Status
aws ec2 describe-vpcs --vpc-ids <YOUR_VPC_ID> --query "Vpcs[0].State"
# Expected: "available"

# Verify 6 Subnets across 2 AZs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<YOUR_VPC_ID>" --query "length(Subnets)"
# Expected: 6
```

### Phase 2: Database Layer Validation
```bash
# Connect to RDS MySQL from a private App EC2 instance
mysql -h college-results-db.cz8qg2i2wvkk.us-east-2.rds.amazonaws.com -u collegeuser -p college_results -e "SELECT count(*) FROM students;"
```
Expected Output:
```
+----------+
| count(*) |
+----------+
|        3 |
+----------+
```

### Phase 3: Application Tier Unit Testing
```bash
# Test local App health endpoint
curl -i http://127.0.0.1:8000/health
# Expected: HTTP/1.1 200 OK, Body: {"database":"connected","status":"healthy"}

# Test student lookup API locally
curl "http://127.0.0.1:8000/api/check_result?reg_no=CSE2025001&dob=2002-02-14"
# Expected: Valid JSON payload returning student details for "Arjun K".
```

### Phase 4: Internal Load Balancer Testing
```bash
# Execute from a Web EC2 node targeting Internal ALB
curl -i http://internal-college-results-internal-alb-499729443.us-east-2.elb.amazonaws.com/health
# Expected: HTTP/1.1 200 OK
```

### Phase 5: Web Tier & Reverse Proxy Testing
```bash
# Execute on Web EC2 node
curl -i http://127.0.0.1/health
# Expected: HTTP/1.1 200 OK, Body: healthy

curl -i http://127.0.0.1/api/health
# Expected: HTTP/1.1 200 OK (Proxied via Internal ALB to App tier)
```

### Phase 6: External Load Balancer & Public DNS Validation
```bash
# Test public HTTP endpoint
curl -i http://college-results-external-alb-233355692.us-east-2.elb.amazonaws.com/health
# Expected: HTTP/1.1 200 OK

# DNS Resolution
dig adhithyan.dpdns.org +short
# Expected: Returns External ALB IP addresses

# HTTPS Test
curl -I https://adhithyan.dpdns.org
# Expected: HTTP/2 200 or HTTP/1.1 200 OK
```

## 3. End-to-End Functional Test
Open web browser -> Navigate to `https://adhithyan.dpdns.org`:
1. Enter Registration Number: `CSE2025001`.
2. Select Date of Birth: `2002-02-14`.
3. Click **Check Result**.
4. Verify rendering of student info card ("Arjun K"), subject marks table, and overall result summary ("Pass", Percentage "81.5%").

---

## 4. Test Results Summary
- **VPC & Subnets**: PASS
- **RDS Database**: PASS
- **Flask Application**: PASS
- **Internal ALB**: PASS
- **NGINX Web Server**: PASS
- **External ALB**: PASS
- **Route 53 & HTTPS**: PASS
