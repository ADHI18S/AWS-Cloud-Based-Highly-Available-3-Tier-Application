# Web Tier (NGINX on EC2)

## 1. What is it?
The Web Tier provides the frontend presentation layer for the application, serving HTML, CSS, and JavaScript files directly to client browsers and acting as a reverse proxy for API traffic.

## 2. Why are we using it?
NGINX is an ultra-fast, lightweight web server capable of handling high-concurrency static asset delivery, SSL offloading support, and reverse proxy request routing.

## 3. Where does it fit in our architecture?
Deployed on EC2 instances running inside Public Web Subnets (`Public-Web-2a` and `Public-Web-2b`), managed by the Web Auto Scaling Group behind the External ALB.

## 4. Architecture
```
External ALB :80 ---> NGINX Web EC2 :80
                       ├── Static Assets (/var/www/html) -> Serve Directly
                       └── API Endpoint (/api/)         -> Proxy to Internal ALB
```

## 5. Configuration used in this project
- **Operating System**: Ubuntu 22.04 LTS
- **Web Root**: `/var/www/html`
- **Active Configuration**: `/etc/nginx/sites-available/college-results` (Symlinked to `/etc/nginx/sites-enabled/college-results`)
- **Default Site**: Removed (`/etc/nginx/sites-enabled/default` deleted)

### NGINX Site Virtual Host Configuration
```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/html;
    index index.html;

    location = /health {
        access_log off;
        default_type text/plain;
        return 200 "healthy
";
    }

    location /api/ {
        proxy_pass http://internal-college-results-internal-alb-499729443.us-east-2.elb.amazonaws.com;
        proxy_http_version 1.1;

        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

## 6. Step-by-step implementation
1. Instance provisioned via Web Launch Template in public subnet.
2. User Data script installs `nginx` and `git`.
3. Clones repository `https://github.com/ADHI18S/temp.git` to `/tmp/college-results-repo`.
4. Copies static frontend files (`index.html`, `script.js`, `styles.css`) to `/var/www/html/`.
5. Generates `/etc/nginx/sites-available/college-results` with proxy rules to Internal ALB.
6. Removes default site, enables `college-results`, tests config via `nginx -t`, and restarts NGINX.

## 7. How it communicates with other components
Receives HTTP traffic from External ALB on port 80. Serves static files locally and proxies `/api/` HTTP requests to the Internal ALB DNS endpoint.

## 8. Security configuration
- Inbound traffic allowed exclusively on port 80 from `External-ALB-SG`.
- Security headers enforced (`X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`).

## 9. Validation
```bash
sudo nginx -t
sudo systemctl status nginx
curl -i http://127.0.0.1/health
curl -i http://127.0.0.1/api/health
```

## 10. Troubleshooting
- **Issue**: `/health` endpoint returns `404 Not Found`.
- **Cause**: Default NGINX site file was not removed, taking precedence over `college-results`.
- **Fix**: Remove `/etc/nginx/sites-enabled/default` and execute `sudo systemctl reload nginx`.

## 11. Common mistakes
- Hardcoding backend IP addresses in `script.js` instead of using relative `/api/` endpoints.
- Forgetting to pass proxy headers (`X-Real-IP`, `Host`).

## 12. Production recommendations
- Enable Gzip / Brotli compression for static CSS and JavaScript assets.

## 13. Related components
- External ALB
- Internal ALB
- Frontend JavaScript

## 14. What we learned
Using NGINX as a reverse proxy decouples frontend client code from internal microservice DNS endpoints.
