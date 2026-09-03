# ==============================================================================
# Environment Configuration Template
# Copy this file to config.py or set environment variables in your cloud runner
# ==============================================================================

# Database Configuration (supports both MYSQL_* and DB_* env vars)
MYSQL_HOST = 'localhost'       # e.g., 'rds-endpoint.us-east-2.rds.amazonaws.com'
MYSQL_USER = 'collegeuser'     # e.g., 'admin'
MYSQL_PASSWORD = ''            # Set via environment variable DB_PASSWORD / MYSQL_PASSWORD
MYSQL_DB = 'college_results'   # Database name
MYSQL_PORT = 3306              # MySQL port (default 3306)
MYSQL_SSL_CA = None            # Path to SSL CA certificate (if required by AWS RDS / Cloud DB)

# Application Server Configuration
APP_PORT = 8000                # App server port (default 8000)
DEBUG = False                  # Debug mode (False for production)
SECRET_KEY = 'change-me-in-production'

# College Branding
COLLEGE_NAME = 'Chennai University'
