# Amazon RDS MySQL Database

## 1. What is it?
Amazon Relational Database Service (RDS) is a managed web service that makes it easy to set up, operate, and scale a relational database in the AWS Cloud.

## 2. Why are we using it?
To store college examination results, student registration profiles, courses, and subject marks securely with high availability, automated backups, and Multi-AZ failover.

## 3. Where does it fit in our architecture?
Deployed in the Private Database subnets (`Private-DB-2a` and `Private-DB-2b`), accessible exclusively on TCP port 3306 by Application EC2 instances.

## 4. Architecture
```
App EC2 (Private App Subnet) ---> TCP 3306 ---> RDS Primary (Private-DB-2b)
                                                    | (Synchronous Replication)
                                                    v
                                                RDS Standby (Private-DB-2a)
```

## 5. Configuration used in this project
- **DB Identifier**: `college-results-db`
- **Engine**: MySQL 8.0 Community Edition
- **Instance Class**: `db.t3.micro`
- **Storage**: 20 GB GP2 (Encrypted at rest)
- **Deployment**: Multi-AZ (Primary in `us-east-2b`, Standby in `us-east-2a`)
- **Database Name**: `college_results`
- **Master Username**: `collegeuser`
- **Endpoint**: `college-results-db.cz8qg2i2wvkk.us-east-2.rds.amazonaws.com`
- **Security Group**: `DB-SG` (Allows port 3306 from `App-SG` only)

## 6. Step-by-step implementation
1. Create DB Subnet Group: VPC -> DB Subnet Groups -> Create (`Private-DB-2a`, `Private-DB-2b`).
2. RDS -> Databases -> Create Database.
3. Select Standard Create -> MySQL -> Version 8.0.
4. Templates: Production -> Multi-AZ DB Instance.
5. Settings: DB Instance Identifier `college-results-db`, Master Username `collegeuser`.
6. Storage: 20 GB GP2, Storage Encryption Enabled.
7. Connectivity: Select `college-results-prod-vpc`, DB Subnet Group, Public Access: **No**, Security Group: `DB-SG`.
8. Initial Database Name: `college_results`. Click **Create Database**.

## 7. Database Schema & Import
Import `database_schema.sql` containing schema definition and seed data:
```sql
CREATE TABLE courses (course_id INT AUTO_INCREMENT PRIMARY KEY, course_name VARCHAR(100));
CREATE TABLE subjects (subject_id INT AUTO_INCREMENT PRIMARY KEY, subject_code VARCHAR(20), subject_name VARCHAR(100), course_id INT, semester INT, max_marks INT);
CREATE TABLE students (student_id INT AUTO_INCREMENT PRIMARY KEY, student_name VARCHAR(100), registration_number VARCHAR(50) UNIQUE, roll_number VARCHAR(50), course_id INT, semester INT, academic_year VARCHAR(20), date_of_birth DATE);
CREATE TABLE results (result_id INT AUTO_INCREMENT PRIMARY KEY, student_id INT, subject_id INT, internal_marks INT, external_marks INT, grade VARCHAR(5));
```

Validation command from an App EC2 node:
```bash
mysql -h college-results-db.cz8qg2i2wvkk.us-east-2.rds.amazonaws.com -u collegeuser -p college_results -e "SHOW TABLES;"
```

> 📸 Screenshot: RDS Configuration Console
> ![RDS Configuration](images/rds-configuration.png)

## 8. Security configuration
- Database is isolated in private database subnets with no public internet access.
- Inbound traffic restricted to port 3306 from `App-SG` only.
- Storage encryption enabled using AWS KMS default key.

## 9. Validation
Connect from App EC2 and query database summary:
```sql
SELECT count(*) FROM students;
```

## 10. Troubleshooting
- **Issue**: `ERROR 2003 (HY000): Can't connect to MySQL server`.
- **Cause**: Security group misconfiguration or DNS resolution failure.
- **Fix**: Verify App EC2 security group is authorized in `DB-SG` inbound rules.

## 11. Common mistakes
- Setting Publicly Accessible to `Yes`.
- Using hardcoded database credentials in application code repository.

## 12. Production recommendations
- Implement AWS Secrets Manager for automatic DB credential rotation.
- Enable Performance Insights and CloudWatch DB Log exports.

## 13. Related components
- DB Subnet Group
- App EC2
- DB Security Group

## 14. What we learned
Managed RDS Multi-AZ removes database management overhead and guarantees seamless failover during single-AZ outages.
