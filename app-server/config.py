import os

# Try loading environment variables from .env file if python-dotenv is installed
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# MySQL Database Configuration
# Support both MYSQL_* and DB_* environment variable naming conventions
MYSQL_HOST = os.getenv("MYSQL_HOST") or os.getenv("DB_HOST", "localhost")
MYSQL_USER = os.getenv("MYSQL_USER") or os.getenv("DB_USER", "collegeuser")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD") or os.getenv("DB_PASSWORD") or os.getenv("MYSQL_PASS") or os.getenv("DB_PASS", "")
MYSQL_DB = os.getenv("MYSQL_DB") or os.getenv("DB_NAME", "college_results")

# Database Port (default MySQL port 3306)
try:
    MYSQL_PORT = int(os.getenv("MYSQL_PORT") or os.getenv("DB_PORT", "3306"))
except ValueError:
    MYSQL_PORT = 3306

# Optional SSL / TLS CA certificate file path for Cloud DBs (AWS RDS, Cloud SQL, Azure Database)
MYSQL_SSL_CA = os.getenv("MYSQL_SSL_CA") or os.getenv("DB_SSL_CA", None)

# Application Configuration
try:
    APP_PORT = int(os.getenv("APP_PORT") or os.getenv("PORT", "8000"))
except ValueError:
    APP_PORT = 8000

DEBUG = os.getenv("DEBUG", "False").lower() in ("true", "1", "t", "yes")

# Secret key for session security / CSRF protection
SECRET_KEY = os.getenv("SECRET_KEY", os.urandom(24).hex())

# College Branding
COLLEGE_NAME = os.getenv("COLLEGE_NAME", "Chennai University")