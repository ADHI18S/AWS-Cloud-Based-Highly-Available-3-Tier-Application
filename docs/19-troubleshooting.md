# Troubleshooting & Failure Analysis

## 1. Overview
During the execution and deployment of this 3-tier architecture, several real-world failure scenarios were encountered. This guide documents the root cause analysis, error logs, and immediate resolution steps for each issue.

---

## 2. Issue Breakdown & Resolutions

### Scenario 1: App systemd service fails with exit code 217 (`status=217/USER`)
- **Symptom**: `college-results.service` failed to start upon EC2 launch.
- **Log Snippet**:
  ```text
  systemd[1]: college-results.service: Failed to determine user credentials: No such process
  systemd[1]: college-results.service: Failed at step USER spawning /opt/college-results/app-server/temp/venv/bin/gunicorn: No such process
  ```
- **Root Cause**: The unit file declared `User=ssm-user`, but the `ssm-user` Linux account was not yet created when cloud-init executed systemd service activation.
- **Fix**: Added explicit user creation in `backend-launch-temp.sh` before enabling the service:
  ```bash
  id -u ssm-user &>/dev/null || useradd -m -s /bin/bash ssm-user
  ```

---

### Scenario 2: Application `/health` returns status `503` (Database Connection Refused)
- **Symptom**: Internal ALB marked App instances `unhealthy`.
- **Log Snippet**:
  ```text
  pymysql.err.OperationalError: (2003, "Can't connect to MySQL server on 'localhost' (111)")
  ```
- **Root Cause**: The Flask config fell back to `localhost` default string when environment variables were missing, attempting to connect to a local MySQL daemon instead of RDS.
- **Fix**: Updated `config.py` to read `DB_HOST` dynamically and verify `conn.ping(reconnect=True)`. Ensured `.env` file generation in User Data wrote the exact RDS endpoint:
  ```bash
  MYSQL_HOST=college-results-db.cz8qg2i2wvkk.us-east-2.rds.amazonaws.com
  ```

---

### Scenario 3: Web tier deployment fails to copy repository files
- **Symptom**: NGINX served standard Ubuntu default landing page instead of college website frontend.
- **Log Snippet**:
  ```text
  cp: cannot stat '/tmp/college-results-repo/web-server/*': No such file or directory
  ```
- **Root Cause**: Git repository root path differed from expected subfolder layout.
- **Fix**: Updated `frontend-launch-temp.sh` to copy directly from repository root:
  ```bash
  cp -r /tmp/college-results-repo/* /var/www/html/
  ```

---

### Scenario 4: NGINX `/health` returns `404 Not Found`
- **Symptom**: Target Group health check failed on port 80.
- **Root Cause**: Default NGINX virtual host (`/etc/nginx/sites-enabled/default`) remained active and intercepted traffic before `college-results` site configuration.
- **Fix**: Explicitly deleted default site symlink:
  ```bash
  rm -f /etc/nginx/sites-enabled/default
  systemctl reload nginx
  ```

---

### Scenario 5: ALB Target Group displays status `502 Bad Gateway`
- **Symptom**: External ALB returned HTTP 502 error to client browser.
- **Root Cause**: Web tier Security Group (`Web-SG`) was missing an ingress rule allowing traffic from `External-ALB-SG`.
- **Fix**: Updated `Web-SG` inbound rules to allow TCP Port 80 from source `External-ALB-SG`.

---

### Scenario 6: ACM Certificate unable to attach to ALB
- **Symptom**: Certificate request created, but dropdown in ALB listener showed "No certificates available".
- **Root Cause**: Certificate was requested in `us-east-1` (N. Virginia) instead of `us-east-2` (Ohio).
- **Fix**: Re-requested certificate explicitly in `us-east-2`.

---

### Scenario 7: Route 53 domain fails to resolve
- **Symptom**: `nslookup adhithyan.dpdns.org` failed with `NXDOMAIN`.
- **Root Cause**: Domain registrar NS records were pointing to external third-party DNS instead of AWS Route 53 Name Servers.
- **Fix**: Copied Route 53 NS record values and updated domain delegation in registrar portal.
