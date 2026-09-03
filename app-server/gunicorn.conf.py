# Gunicorn configuration file for Flask Application Tier (Production Cloud Deployment)
import os

# Dynamic binding port (supports APP_PORT or PORT env vars)
port = os.getenv("APP_PORT", os.getenv("PORT", "8000"))
bind = f"0.0.0.0:{port}"

# Worker processes and threading configuration
workers = int(os.getenv("GUNICORN_WORKERS", "2"))
threads = int(os.getenv("GUNICORN_THREADS", "2"))
worker_class = os.getenv("GUNICORN_WORKER_CLASS", "gthread")
timeout = int(os.getenv("GUNICORN_TIMEOUT", "60"))
keepalive = int(os.getenv("GUNICORN_KEEPALIVE", "5"))

# Logging: Output to stdout ("-") and stderr ("-") by default for CloudWatch, Docker & systemd
accesslog = os.getenv("GUNICORN_ACCESS_LOG", "-")
errorlog = os.getenv("GUNICORN_ERROR_LOG", "-")
loglevel = os.getenv("GUNICORN_LOG_LEVEL", "info")

# App preloading for efficient memory footprint across workers
preload_app = True

# Security & Proxy headers configuration
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190
forwarded_allow_ips = os.getenv("FORWARDED_ALLOW_IPS", "*")
