import os
import sys
import math
import logging
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory, make_response
from flask_mysqldb import MySQL

# Configure production logging to stdout for AWS CloudWatch, Docker, and Kubernetes
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger('app_server')

# Load configuration module if available
try:
    import config
except Exception as e:
    logger.warning(f"Could not import config module ({e}); falling back to environment variables.")
    config = None

app = Flask(__name__, static_folder='.', static_url_path='')

# Load App Configuration dynamically
if config:
    app.config['MYSQL_HOST'] = getattr(config, 'MYSQL_HOST', 'localhost')
    app.config['MYSQL_USER'] = getattr(config, 'MYSQL_USER', 'collegeuser')
    app.config['MYSQL_PASSWORD'] = getattr(config, 'MYSQL_PASSWORD', '')
    app.config['MYSQL_DB'] = getattr(config, 'MYSQL_DB', 'college_results')
    app.config['MYSQL_PORT'] = getattr(config, 'MYSQL_PORT', 3306)
    app.config['COLLEGE_NAME'] = getattr(config, 'COLLEGE_NAME', 'Chennai University')
    app.config['SECRET_KEY'] = getattr(config, 'SECRET_KEY', 'default-secret-key')
    ssl_ca = getattr(config, 'MYSQL_SSL_CA', None)
    if ssl_ca:
        app.config['MYSQL_CUSTOM_OPTIONS'] = {'ssl': {'ca': ssl_ca}}
else:
    app.config['MYSQL_HOST'] = os.getenv('MYSQL_HOST', os.getenv('DB_HOST', 'localhost'))
    app.config['MYSQL_USER'] = os.getenv('MYSQL_USER', os.getenv('DB_USER', 'collegeuser'))
    app.config['MYSQL_PASSWORD'] = os.getenv('MYSQL_PASSWORD', os.getenv('DB_PASSWORD', ''))
    app.config['MYSQL_DB'] = os.getenv('MYSQL_DB', os.getenv('DB_NAME', 'college_results'))
    try:
        app.config['MYSQL_PORT'] = int(os.getenv('MYSQL_PORT', os.getenv('DB_PORT', '3306')))
    except ValueError:
        app.config['MYSQL_PORT'] = 3306
    app.config['COLLEGE_NAME'] = os.getenv('COLLEGE_NAME', 'Chennai University')
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'default-secret-key')

# Connection timeout to prevent worker hangs (10 seconds)
app.config['MYSQL_CONNECT_TIMEOUT'] = 10

# Initialize MySQL extension
mysql = MySQL(app)


# Middleware: Global CORS support for cloud multi-tier setups
@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    return response


def get_db_cursor():
    """
    Safely retrieves a database cursor and verifies connection state.
    Auto-reconnects if MySQL connection has timed out.
    """
    try:
        conn = mysql.connection
        # Ping DB connection and reconnect if connection was dropped by RDS/MySQL idle timeout
        conn.ping(True)
        return conn.cursor()
    except Exception as e:
        logger.error(f"Failed to get active database cursor: {e}")
        raise


@app.route('/')
def index():
    # Serve static index.html (single page app)
    return send_from_directory('.', 'index.html')


# Health check endpoints for AWS ALB / NLB Target Groups, K8s probes, and CloudWatch
@app.route('/health', methods=['GET'])
@app.route('/api/health', methods=['GET'])
def health_check():
    db_status = "disconnected"
    http_code = 200
    try:
        cur = get_db_cursor()
        cur.execute("SELECT 1")
        cur.fetchone()
        cur.close()
        db_status = "connected"
    except Exception as e:
        logger.error(f"Health check database ping failed: {e}")
        db_status = f"error: {str(e)}"
        # Return 503 if database connection is completely down so load balancer can handle target health
        http_code = 503

    return jsonify({
        'status': 'healthy' if db_status == 'connected' else 'unhealthy',
        'database': db_status,
        'college_name': app.config.get('COLLEGE_NAME'),
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    }), http_code


def fetch_student_by_reg_and_dob(reg_no, dob_str):
    """
    Returns student dict or None. dob_str expected 'YYYY-MM-DD'
    """
    cur = get_db_cursor()
    try:
        q = """
        SELECT s.student_id, s.student_name, s.registration_number, s.roll_number, s.course_id,
               c.course_name, s.semester, s.academic_year, s.date_of_birth
        FROM students s
        JOIN courses c ON s.course_id = c.course_id
        WHERE s.registration_number = %s AND s.date_of_birth = %s
        LIMIT 1
        """
        cur.execute(q, (reg_no, dob_str))
        row = cur.fetchone()
        if not row:
            return None
        student = {
            'student_id': row[0],
            'student_name': row[1],
            'registration_number': row[2],
            'roll_number': row[3],
            'course_id': row[4],
            'course_name': row[5],
            'semester': row[6],
            'academic_year': row[7],
            'date_of_birth': row[8].strftime('%Y-%m-%d') if isinstance(row[8], (datetime,)) else str(row[8])
        }
        return student
    finally:
        cur.close()


def fetch_results_for_student(student_id, course_id, semester):
    """
    return list of dicts: subject_code, subject_name, internal_marks, external_marks, max_marks, grade
    """
    cur = get_db_cursor()
    try:
        q = """
        SELECT sub.subject_id, sub.subject_code, sub.subject_name, sub.max_marks,
               IFNULL(r.internal_marks, 0), IFNULL(r.external_marks, 0), IFNULL(r.grade, '') 
        FROM subjects sub
        LEFT JOIN results r ON r.subject_id = sub.subject_id AND r.student_id = %s
        WHERE sub.course_id = %s AND sub.semester = %s
        ORDER BY sub.subject_id
        """
        cur.execute(q, (student_id, course_id, semester))
        rows = cur.fetchall()
        results = []
        for row in rows:
            subject_id, code, name, max_marks, internal, external, grade = row
            total = (internal or 0) + (external or 0)
            threshold = math.ceil(0.40 * (max_marks or 100))
            status = 'Pass' if total >= threshold else 'Fail'
            results.append({
                'subject_id': subject_id,
                'subject_code': code,
                'subject_name': name,
                'internal_marks': int(internal or 0),
                'external_marks': int(external or 0),
                'total_marks': int(total),
                'max_marks': int(max_marks or 100),
                'grade': grade or ''
            })
        return results
    finally:
        cur.close()


def grade_from_percentage(pct):
    # Simple grade mapping
    if pct >= 85: return 'O'
    if pct >= 75: return 'A+'
    if pct >= 65: return 'A'
    if pct >= 55: return 'B+'
    if pct >= 45: return 'B'
    if pct >= 40: return 'C'
    return 'F'


# Route supporting both /check_result and /api/check_result (with pre-flight OPTIONS support)
@app.route('/check_result', methods=['POST', 'OPTIONS'])
@app.route('/api/check_result', methods=['POST', 'OPTIONS'])
def check_result():
    if request.method == 'OPTIONS':
        return make_response('', 200)

    try:
        data = request.get_json(force=True, silent=True)
        if not data:
            return jsonify(error='Invalid JSON request payload.'), 400

        reg_no = str(data.get('registration_number', '')).strip()
        dob = str(data.get('date_of_birth', '')).strip()

        # Server-side validation
        if not reg_no or not dob:
            return jsonify(error='Registration number and Date of Birth are required.'), 400
        try:
            # normalize dob -> YYYY-MM-DD
            dob_dt = datetime.strptime(dob, '%Y-%m-%d').date()
        except Exception:
            return jsonify(error='Date of Birth must be in YYYY-MM-DD format.'), 400

        # Fetch student with try/except DB protection
        try:
            student = fetch_student_by_reg_and_dob(reg_no, dob_dt.strftime('%Y-%m-%d'))
        except Exception as dberr:
            logger.error(f"Database error during student lookup: {dberr}")
            return jsonify(error='Database service unavailable. Please try again later.'), 500

        if not student:
            return jsonify(error='Student not found. Please check Registration Number and Date of Birth.'), 404

        # Fetch results with try/except DB protection
        try:
            results = fetch_results_for_student(student['student_id'], student['course_id'], student['semester'])
        except Exception as dberr:
            logger.error(f"Database error during results lookup: {dberr}")
            return jsonify(error='Database service unavailable. Please try again later.'), 500

        # Summarize
        total_obtained = sum(r['total_marks'] for r in results)
        total_max = sum(r['max_marks'] for r in results)
        percentage = (total_obtained / total_max * 100) if total_max > 0 else 0.0

        # Determine pass/fail: any subject with status Fail causes overall fail
        fail_any = any(r['total_marks'] < math.ceil(0.40 * r['max_marks']) for r in results)
        # Derive grade
        overall_grade = grade_from_percentage(percentage)
        overall_status = 'Fail' if fail_any or overall_grade == 'F' else 'Pass'

        # Attach status to each result for client display
        for r in results:
            threshold = math.ceil(0.40 * r['max_marks'])
            r['status'] = 'Pass' if r['total_marks'] >= threshold else 'Fail'

        response = {
            'student': {
                'student_name': student['student_name'],
                'registration_number': student['registration_number'],
                'roll_number': student['roll_number'],
                'course_name': student['course_name'],
                'semester': student['semester'],
                'academic_year': student['academic_year'],
                'date_of_birth': student['date_of_birth'],
            },
            'results': results,
            'summary': {
                'total_obtained': total_obtained,
                'total_max': total_max,
                'percentage': percentage,
                'grade': overall_grade,
                'status': overall_status
            }
        }

        return jsonify(response), 200

    except Exception as general_err:
        logger.error(f"Unexpected error in check_result: {general_err}", exc_info=True)
        return jsonify(error='An unexpected error occurred. Please try again later.'), 500


if __name__ == '__main__':
    port = getattr(config, 'APP_PORT', 8000) if config else int(os.getenv('APP_PORT', os.getenv('PORT', 8000)))
    debug = getattr(config, 'DEBUG', False) if config else (os.getenv('DEBUG', 'False').lower() in ('true', '1'))
    logger.info(f"Starting College Results App Server on 0.0.0.0:{port} (debug={debug})")
    app.run(host='0.0.0.0', port=port, debug=debug)
