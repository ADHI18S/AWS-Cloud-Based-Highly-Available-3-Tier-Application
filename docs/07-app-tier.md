# Application Tier (Flask & Gunicorn on EC2)

## 1. What is it?
The Application Tier handles business logic, database connectivity, and API endpoints for student exam result lookups. It is powered by a Python Flask microframework executed under the Gunicorn WSGI server.

## 2. Why are we using it?
Decoupling application logic from the web server allows scaling backend compute dynamically based on API load independently of static frontend asset requests.

## 3. Where does it fit in our architecture?
Deploys on EC2 instances running inside Private Application Subnets (`Private-App-2a` and `Private-App-2b`). Receives API traffic on port 8000 from the Internal ALB and queries RDS MySQL on port 3306.

## 4. Architecture
```
Internal ALB :80 ---> App EC2 :8000 (Gunicorn WSGI) ---> Flask (app:app) ---> PyMySQL ---> RDS MySQL :3306
```

## 5. Configuration used in this project
- **Operating System**: Ubuntu 22.04 LTS
- **Application Directory**: `/opt/college-results/app-server/temp`
- **WSGI Server**: Gunicorn (configured via `gunicorn.conf.py`)
- **Port**: `8000`
- **Environment File**: `/opt/college-results/app-server/temp/.env`
- **Systemd Service**: `college-results.service`
- **Execution User**: `ssm-user`

### Systemd Configuration (`/etc/systemd/system/college-results.service`)
```ini
[Unit]
Description=College Results Flask Application
After=network.target

[Service]
User=ssm-user
Group=ssm-user
WorkingDirectory=/opt/college-results/app-server/temp
Environment="PATH=/opt/college-results/app-server/temp/venv/bin"
ExecStart=/opt/college-results/app-server/temp/venv/bin/gunicorn -c gunicorn.conf.py app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## 6. Step-by-step implementation
1. Instance provisioned via Launch Template in private application subnet.
2. User Data script updates packages and installs `python3-pip`, `python3-venv`, `git`, and MySQL client headers.
3. Clones repository `https://github.com/ADHI18S/temp.git` into `/opt/college-results/app-server/temp`.
4. Creates Python virtual environment and installs `requirements.txt`.
5. Creates `.env` configuration file with RDS endpoint parameters.
6. Installs and starts `college-results.service` via `systemctl`.

## 7. How it communicates with other components
Listens for HTTP API requests from the Internal ALB on TCP 8000. Communicates with RDS MySQL on TCP 3306 using dynamic connection ping verification to handle database idle disconnects.

## 8. Security configuration
- No public IP address assigned.
- Inbound traffic restricted to TCP port 8000 from `Internal-ALB-SG` only.
- `.env` file permissions set to `600`.

## 9. Validation
Log into App instance via SSM Session Manager:
```bash
sudo systemctl status college-results.service
sudo ss -lntp | grep 8000
curl http://127.0.0.1:8000/health
curl "http://127.0.0.1:8000/api/check_result?reg_no=CSE2025001&dob=2002-02-14"
```
Expected output for health: `{"status": "healthy", "database": "connected"}`.

## 10. Troubleshooting
- **Issue**: `college-results.service` fails with status `code=exited, status=217/USER`.
- **Cause**: The systemd service specifies `User=ssm-user`, but `ssm-user` has not been created on the instance yet.
- **Fix**: Ensure SSM agent initializes `ssm-user` or explicitly create the user in User Data before starting systemd.

## 11. Common mistakes
- Running Flask with default built-in development server (`app.run()`) instead of Gunicorn WSGI in production.
- Hardcoding database passwords inside `config.py` instead of loading via `os.getenv()`.

## 12. Production recommendations
- Store dynamic configuration in AWS Systems Manager Parameter Store or Secrets Manager.

## 13. Related components
- Internal ALB
- Amazon RDS MySQL
- Gunicorn WSGI

## 14. What we learned
Using systemd ensures application auto-restart on crashes and standardizes logging to `journalctl` / CloudWatch.
