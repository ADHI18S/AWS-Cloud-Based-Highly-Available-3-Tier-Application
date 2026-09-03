# Route Tables

## 1. What is it?
A route table contains a set of rules, called routes, that are used to determine where network traffic from your subnet or gateway is directed.

## 2. Why are we using it?
To control packet routing across our three distinct architecture tiers (Web, App, DB) and enforce strict network access boundaries.

## 3. Where does it fit in our architecture?
Every subnet in `college-results-prod-vpc` is explicitly associated with a route table governing its traffic destinations.

## 4. Architecture
```
Subnets                      Route Tables                          Gateways
Public-Web-2a/2b    --->  college-results-prod-public-rt       ---> IGW (Internet)
Private-App-2a/2b   --->  college-results-prod-private-app-rt   ---> NAT Gateway
Private-DB-2a/2b    --->  college-results-prod-private-db-rt    ---> Local Only (No Internet)
```

## 5. Configuration used in this project
### Public Route Table (`college-results-prod-public-rt`)
- `10.0.0.0/16` -> `local`
- `0.0.0.0/0` -> `igw-xxxx`
- **Associated Subnets**: `Public-Web-2a`, `Public-Web-2b`

### Private App Route Table (`college-results-prod-private-app-rt`)
- `10.0.0.0/16` -> `local`
- `0.0.0.0/0` -> `nat-xxxx`
- **Associated Subnets**: `Private-App-2a`, `Private-App-2b`

### Private DB Route Table (`college-results-prod-private-db-rt`)
- `10.0.0.0/16` -> `local`
- **Associated Subnets**: `Private-DB-2a`, `Private-DB-2b` (No internet route!)

## 6. Step-by-step implementation
1. VPC -> Route Tables -> Create Route Table.
2. Create `college-results-prod-public-rt`, attach to VPC, add route `0.0.0.0/0 -> IGW`, associate Public subnets.
3. Create `college-results-prod-private-app-rt`, attach to VPC, add route `0.0.0.0/0 -> NAT Gateway`, associate Private App subnets.
4. Create `college-results-prod-private-db-rt`, attach to VPC, keep default local route only, associate Private DB subnets.

## 7. How it communicates with other components
Directs packets based on destination IP lookup against table entries.

## 8. Security configuration
- Database subnets are completely isolated from internet gateways and NAT gateways.

## 9. Validation
```bash
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<YOUR_VPC_ID>" --output table
```

## 10. Troubleshooting
- **Issue**: Instances in private app subnet can ping internal IP addresses but cannot reach external endpoints.
- **Cause**: Private App route table is missing the `0.0.0.0/0 -> NAT` entry.

## 11. Common mistakes
- Associating private database subnets with the public route table.
- Relying on the main default VPC route table instead of creating explicit named route tables.

## 12. Production recommendations
- Implement explicit subnets associations for 100% predictable route mapping.

## 13. Related components
- VPC
- Internet Gateway
- NAT Gateway

## 14. What we learned
Route tables define the fundamental network paths; isolating DB route tables guarantees zero internet reachability.
