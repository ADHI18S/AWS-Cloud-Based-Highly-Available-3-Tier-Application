from flask import Flask, request, jsonify, send_from_directory
from flask_mysqldb import MySQL
from datetime import datetime
import os
import math

# Load configuration from config.py
try:
    import config
except Exception as e:
    # minimal fallback if config.py missing
    config = None

app = Flask(__name__, static_folder='.', static_url_path='')

# MySQL config (from config.py if present)
if config:
    app.config['MYSQL_HOST'] = getattr(config, 'MYSQL_HOST', 'localhost')
    app.config['MYSQL_USER'] = getattr(config, 'MYSQL_USER', 'root')
    app.config['MYSQL_PASSWORD'] = getattr(config, 'MYSQL_PASSWORD', '')
    app.config['MYSQL_DB'] = getattr(config, 'MYSQL_DB', 'college_results')
    app.config['COLLEGE_NAME'] = getattr(config, 'COLLEGE_NAME', 'ABC Engineering College')
else:
    app.config['MYSQL_HOST'] = os.getenv('MYSQL_HOST', 'localhost')
    app.config['MYSQL_USER'] = os.getenv('MYSQL_USER', 'root')
    app.config['MYSQL_PASSWORD'] = os.getenv('MYSQL_PASSWORD', '')
    app.config['MYSQL_DB'] = os.getenv('MYSQL_DB', 'college_results')
    app.config['COLLEGE_NAME'] = os.getenv('COLLEGE_NAME', 'ABC Engineering College')

mysql = MySQL(app)


@app.route('/')
def index():
    # Serve static index.html (single page app)
    return send_from_directory('.', 'index.html')


def fetch_student_by_reg_and_dob(reg_no, dob_str):
    """
    Returns student dict or None. dob_str expected 'YYYY-MM-DD'
    """
    cur = mysql.connection.cursor()
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
    cur.close()
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


def fetch_results_for_student(student_id, course_id, semester):
    """
    return list of dicts: subject_code, subject_name, internal_marks, external_marks, max_marks, grade
    """
    cur = mysql.connection.cursor()
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
    cur.close()
    results = []
    for row in rows:
        subject_id, code, name, max_marks, internal, external, grade = row
        total = (internal or 0) + (external or 0)
        # determine pass/fail per subject (pass threshold 40% of max marks or external >= 20 and total >= 40% - common simple rule)
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


def grade_from_percentage(pct):
    # Simple grade mapping
    if pct >= 85: return 'O'
    if pct >= 75: return 'A+'
    if pct >= 65: return 'A'
    if pct >= 55: return 'B+'
    if pct >= 45: return 'B'
    if pct >= 40: return 'C'
    return 'F'


@app.route('/check_result', methods=['POST'])
def check_result():
    data = request.get_json(force=True)
    reg_no = data.get('registration_number', '').strip()
    dob = data.get('date_of_birth', '').strip()

    # Server-side validation
    if not reg_no or not dob:
        return jsonify(error='Registration number and Date of Birth are required.'), 400
    try:
        # normalize dob -> YYYY-MM-DD
        dob_dt = datetime.strptime(dob, '%Y-%m-%d').date()
    except Exception:
        return jsonify(error='Date of Birth must be in YYYY-MM-DD format.'), 400

    # Fetch student
    student = fetch_student_by_reg_and_dob(reg_no, dob_dt.strftime('%Y-%m-%d'))
    if not student:
        return jsonify(error='Student not found. Please check Registration Number and Date of Birth.'), 404

    # Fetch results
    results = fetch_results_for_student(student['student_id'], student['course_id'], student['semester'])

    # summarize
    total_obtained = sum(r['total_marks'] for r in results)
    total_max = sum(r['max_marks'] for r in results)
    percentage = (total_obtained / total_max * 100) if total_max > 0 else 0.0

    # determine pass/fail: any subject with status Fail causes overall fail
    fail_any = any(r['total_marks'] < math.ceil(0.40 * r['max_marks']) for r in results)
    # derive grade
    overall_grade = grade_from_percentage(percentage)
    overall_status = 'Fail' if fail_any or overall_grade == 'F' else 'Pass'

    # attach status to each result for client display
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


if __name__ == '__main__':
    port = getattr(config, 'APP_PORT', 5000) if config else int(os.getenv('APP_PORT', 5000))
    debug = getattr(config, 'DEBUG', True) if config else (os.getenv('DEBUG', 'True') == 'True')
    app.run(host='0.0.0.0', port=port, debug=debug)
