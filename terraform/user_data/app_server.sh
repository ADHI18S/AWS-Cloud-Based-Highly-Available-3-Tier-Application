#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# Log all output to user_data.log for debugging
exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting App Server User Data Initialization ==="

# STEP 6: Install required dependencies
echo "Installing required OS packages and MySQL development libraries..."
apt-get update -y
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    mysql-client \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    curl

# STEP 7: Create application directory
APP_DIR="/opt/college-results/app-server"
echo "Creating application directory: $APP_DIR"
mkdir -p "$APP_DIR"
chmod 755 /opt/college-results
chmod 755 "$APP_DIR"

# Database Configuration Variables from Terraform template
DB_HOST="${db_host}"
DB_PORT="${db_port}"
DB_USER="${db_user}"
DB_PASS="${db_password}"
DB_NAME="${db_name}"

# Create application configuration file
cat <<EOF > "$APP_DIR/config.py"
# MySQL Configuration
MYSQL_HOST = '$DB_HOST'
MYSQL_USER = '$DB_USER'
MYSQL_PASSWORD = '$DB_PASS'
MYSQL_DB = '$DB_NAME'
MYSQL_PORT = $DB_PORT

# Application Configuration
APP_PORT = 5000
DEBUG = False

# College Branding
COLLEGE_NAME = 'Chennai University'
EOF

# Create requirements.txt
cat <<'EOF' > "$APP_DIR/requirements.txt"
flask>=3.0.0
mysql-connector-python>=8.2.0
gunicorn>=21.2.0
python-dotenv>=1.0.0
EOF

# Create database_schema.sql
cat <<'EOF' > "$APP_DIR/database_schema.sql"
-- Database schema and sample data for College Exam Result Management System
CREATE DATABASE IF NOT EXISTS college_results DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE college_results;

-- Table: courses
CREATE TABLE IF NOT EXISTS courses (
  course_id INT AUTO_INCREMENT PRIMARY KEY,
  course_name VARCHAR(120) NOT NULL
) ENGINE=InnoDB;

-- Table: subjects
CREATE TABLE IF NOT EXISTS subjects (
  subject_id INT AUTO_INCREMENT PRIMARY KEY,
  subject_code VARCHAR(20) NOT NULL,
  subject_name VARCHAR(120) NOT NULL,
  course_id INT NOT NULL,
  semester INT NOT NULL,
  max_marks INT NOT NULL DEFAULT 100,
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Table: students
CREATE TABLE IF NOT EXISTS students (
  student_id INT AUTO_INCREMENT PRIMARY KEY,
  student_name VARCHAR(150) NOT NULL,
  registration_number VARCHAR(60) UNIQUE NOT NULL,
  roll_number VARCHAR(60) NOT NULL,
  course_id INT NOT NULL,
  semester INT NOT NULL,
  academic_year VARCHAR(20) NOT NULL,
  date_of_birth DATE NOT NULL,
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Table: results
CREATE TABLE IF NOT EXISTS results (
  result_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  subject_id INT NOT NULL,
  grade VARCHAR(6),
  internal_marks INT DEFAULT 0,
  external_marks INT DEFAULT 0,
  FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Seed Data (Insert if empty)
INSERT IGNORE INTO courses (course_id, course_name) VALUES 
(1, 'B.Tech - Computer Science (CSE)'), 
(2, 'B.Tech - Electrical & Electronics (EEE)'), 
(3, 'B.Tech - Mechanical (MECH)');

INSERT IGNORE INTO subjects (subject_id, subject_code, subject_name, course_id, semester, max_marks) VALUES
(1, 'CSE401','Operating Systems', 1, 4, 100),
(2, 'CSE402','Database Systems', 1, 4, 100),
(3, 'CSE403','Computer Networks', 1, 4, 100),
(4, 'CSE404','Software Engineering', 1, 4, 100),
(5, 'MAT404','Discrete Mathematics', 1, 4, 100),
(6, 'ELE401','Microprocessors', 1, 4, 100);

INSERT IGNORE INTO students (student_id, student_name, registration_number, roll_number, course_id, semester, academic_year, date_of_birth) VALUES
(1, 'Arjun K', 'CSE2025001', '21CSE001', 1, 4, '2024-25', '2002-02-14'),
(2, 'Deepa R', 'EEE2025002', '21EEE002', 2, 4, '2024-25', '2001-08-06'),
(3, 'Manoj S', 'MECH2025003', '21MECH003', 3, 4, '2024-25', '2002-11-22');

INSERT IGNORE INTO results (result_id, student_id, subject_id, internal_marks, external_marks, grade) VALUES
(1, 1, 1, 12, 60, 'A'),
(2, 1, 2, 11, 58, 'A'),
(3, 1, 3, 10, 62, 'A+'),
(4, 1, 4, 9, 54, 'B+'),
(5, 1, 5, 8, 50, 'B'),
(6, 1, 6, 7, 55, 'A');
EOF

# STEP 8: Create Python Virtual Environment and Install Requirements
echo "Creating Python virtual environment..."
python3 -m venv "$APP_DIR/venv"

echo "Upgrading pip and installing requirements..."
"$APP_DIR/venv/bin/pip" install --upgrade pip
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"

# STEP 12: Retry connection logic for RDS MySQL
echo "Waiting for RDS MySQL at $DB_HOST:$DB_PORT..."
MAX_RETRIES=30
RETRY_COUNT=0
UNTIL_SUCCESS=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" --silent; then
        echo "RDS MySQL is reachable."
        UNTIL_SUCCESS=1
        break
    fi
    echo "RDS not ready yet. Retrying in 10 seconds... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 10
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $UNTIL_SUCCESS -eq 0 ]; then
    echo "Warning: Timed out waiting for RDS MySQL ping, attempting schema connection anyway..."
fi

# STEP 13: Idempotent Database Schema Import
echo "Checking if database '$DB_NAME' and table 'students' exist in RDS..."
TABLE_EXISTS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME' AND table_name = 'students';" 2>/dev/null || echo "0")

if [ "$TABLE_EXISTS" -gt 0 ]; then
    echo "Database schema and table 'students' already exist. Skipping schema import (Idempotent)."
else
    echo "Schema missing. Creating database '$DB_NAME' and importing schema..."
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" < "$APP_DIR/database_schema.sql"
    echo "Database schema successfully imported into RDS MySQL."
fi

echo "=== User Data Initialization Finished Successfully ==="
