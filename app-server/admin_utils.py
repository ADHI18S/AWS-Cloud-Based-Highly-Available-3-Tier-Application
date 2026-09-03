"""
Admin utilities for management & CLI tasks:
- add_student
- update_result
- export_csv

Usage examples (run from terminal):
python admin_utils.py add_student --name "John Doe" --reg "CSE2025010" --roll "21CSE010" --course 1 --semester 4 --year "2024-25" --dob 2002-03-12
python admin_utils.py update_result --reg CSE2025010 --subject CSE401 --internal 12 --external 56 --grade A
python admin_utils.py export_csv --out results.csv
"""

import os
import csv
import argparse
from datetime import datetime
import MySQLdb

# Load config safely
try:
    import config
except ImportError:
    config = None


def get_db_conn():
    host = getattr(config, 'MYSQL_HOST', None) or os.getenv('MYSQL_HOST') or os.getenv('DB_HOST', 'localhost')
    user = getattr(config, 'MYSQL_USER', None) or os.getenv('MYSQL_USER') or os.getenv('DB_USER', 'collegeuser')
    passwd = getattr(config, 'MYSQL_PASSWORD', None) or os.getenv('MYSQL_PASSWORD') or os.getenv('DB_PASSWORD', '')
    db = getattr(config, 'MYSQL_DB', None) or os.getenv('MYSQL_DB') or os.getenv('DB_NAME', 'college_results')
    port = getattr(config, 'MYSQL_PORT', None) or os.getenv('MYSQL_PORT') or os.getenv('DB_PORT', 3306)

    try:
        port = int(port)
    except ValueError:
        port = 3306

    kwargs = {
        'host': host,
        'user': user,
        'passwd': passwd,
        'db': db,
        'port': port,
        'charset': 'utf8mb4'
    }

    ssl_ca = getattr(config, 'MYSQL_SSL_CA', None) or os.getenv('MYSQL_SSL_CA') or os.getenv('DB_SSL_CA')
    if ssl_ca:
        kwargs['ssl'] = {'ca': ssl_ca}

    return MySQLdb.connect(**kwargs)


def add_student(args):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        q = """INSERT INTO students (student_name, registration_number, roll_number, course_id, semester, academic_year, date_of_birth)
               VALUES (%s,%s,%s,%s,%s,%s,%s)"""
        dob = args.dob
        if isinstance(dob, str):
            dob = datetime.strptime(dob, '%Y-%m-%d').date()
        cur.execute(q, (args.name, args.reg, args.roll, args.course, args.semester, args.year, dob))
        conn.commit()
        print("Student added successfully.")
    finally:
        cur.close()
        conn.close()


def find_student_id(conn, registration_number):
    cur = conn.cursor()
    try:
        cur.execute("SELECT student_id FROM students WHERE registration_number = %s", (registration_number,))
        r = cur.fetchone()
        return r[0] if r else None
    finally:
        cur.close()


def find_subject_id(conn, subject_code):
    cur = conn.cursor()
    try:
        cur.execute("SELECT subject_id FROM subjects WHERE subject_code = %s LIMIT 1", (subject_code,))
        r = cur.fetchone()
        return r[0] if r else None
    finally:
        cur.close()


def update_result(args):
    conn = get_db_conn()
    try:
        sid = find_student_id(conn, args.reg)
        if not sid:
            print(f"Error: Student with registration '{args.reg}' not found.")
            return
        subid = find_subject_id(conn, args.subject)
        if not subid:
            print(f"Error: Subject with code '{args.subject}' not found.")
            return

        cur = conn.cursor()
        try:
            # Upsert: if result exists update else insert
            cur.execute("SELECT result_id FROM results WHERE student_id=%s AND subject_id=%s", (sid, subid))
            r = cur.fetchone()
            if r:
                cur.execute("UPDATE results SET internal_marks=%s, external_marks=%s, grade=%s WHERE result_id=%s",
                            (args.internal, args.external, args.grade, r[0]))
            else:
                cur.execute("INSERT INTO results (student_id, subject_id, internal_marks, external_marks, grade) VALUES (%s,%s,%s,%s,%s)",
                            (sid, subid, args.internal, args.external, args.grade))
            conn.commit()
            print("Result updated successfully.")
        finally:
            cur.close()
    finally:
        conn.close()


def export_csv(args):
    conn = get_db_conn()
    try:
        cur = conn.cursor()
        try:
            q = """
            SELECT st.registration_number, st.student_name, st.roll_number, c.course_name, st.semester, st.academic_year,
                   sub.subject_code, sub.subject_name, r.internal_marks, r.external_marks, r.grade
            FROM students st
            JOIN courses c ON st.course_id=c.course_id
            JOIN results r ON r.student_id = st.student_id
            JOIN subjects sub ON sub.subject_id = r.subject_id
            ORDER BY st.registration_number, sub.subject_code
            """
            cur.execute(q)
            rows = cur.fetchall()
        finally:
            cur.close()
    finally:
        conn.close()

    with open(args.out, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['Registration','Student Name','Roll','Course','Semester','Year','Subject Code','Subject Name','Internal','External','Grade'])
        for row in rows:
            writer.writerow(row)
    print(f"Exported {len(rows)} results to {args.out}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Admin utilities for college results system')
    subparsers = parser.add_subparsers(dest='cmd')

    p_add = subparsers.add_parser('add_student')
    p_add.add_argument('--name', required=True)
    p_add.add_argument('--reg', required=True)
    p_add.add_argument('--roll', required=True)
    p_add.add_argument('--course', required=True, type=int)
    p_add.add_argument('--semester', required=True, type=int)
    p_add.add_argument('--year', required=True)
    p_add.add_argument('--dob', required=True)  # YYYY-MM-DD

    p_upd = subparsers.add_parser('update_result')
    p_upd.add_argument('--reg', required=True)
    p_upd.add_argument('--subject', required=True)
    p_upd.add_argument('--internal', required=True, type=int)
    p_upd.add_argument('--external', required=True, type=int)
    p_upd.add_argument('--grade', required=False, default='')

    p_exp = subparsers.add_parser('export_csv')
    p_exp.add_argument('--out', required=False, default='results_export.csv')

    args = parser.parse_args()
    if args.cmd == 'add_student':
        add_student(args)
    elif args.cmd == 'update_result':
        update_result(args)
    elif args.cmd == 'export_csv':
        export_csv(args)
    else:
        parser.print_help()
