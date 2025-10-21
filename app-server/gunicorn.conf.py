# Gunicorn configuration file for Flask Application Tier

bind = "0.0.0.0:8000"
workers = 2
threads = 2
timeout = 60
keepalive = 5

# Use 'sync' for most Flask APIs, or 'gthread' if expecting high concurrency
worker_class = "gthread"

# Access and error logs (optional, for debugging)
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
loglevel = "info"

# Allow a graceful restart
preload_app = True

# Security: Limit request line and field size to prevent abuses (optional)
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Recommended for production behind a load balancer
forwarded_allow_ips = "127.0.0.1,*"
