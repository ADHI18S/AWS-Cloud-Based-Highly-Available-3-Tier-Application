-- Database schema and sample data for College Exam Result Management System
-- Create database (run as a privileged user)
CREATE DATABASE IF NOT EXISTS college_results DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE college_results;

-- Table: courses
DROP TABLE IF EXISTS courses;
CREATE TABLE courses (
  course_id INT AUTO_INCREMENT PRIMARY KEY,
  course_name VARCHAR(120) NOT NULL
) ENGINE=InnoDB;

-- Table: subjects
DROP TABLE IF EXISTS subjects;
CREATE TABLE subjects (
  subject_id INT AUTO_INCREMENT PRIMARY KEY,
  subject_code VARCHAR(20) NOT NULL,
  subject_name VARCHAR(120) NOT NULL,
  course_id INT NOT NULL,
  semester INT NOT NULL,
  max_marks INT NOT NULL DEFAULT 100,
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Table: students
DROP TABLE IF EXISTS students;
CREATE TABLE students (
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
DROP TABLE IF EXISTS results;
CREATE TABLE results (
  result_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  subject_id INT NOT NULL,
  grade VARCHAR(6),
  internal_marks INT DEFAULT 0,
  external_marks INT DEFAULT 0,
  FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- Insert courses
INSERT INTO courses (course_name) VALUES ('B.Tech - Computer Science (CSE)'), ('B.Tech - Electrical & Electronics (EEE)'), ('B.Tech - Mechanical (MECH)');

-- Insert subjects for each course - 6 subjects each for semester 4 (example).
-- We'll assume semester = 4 for sample students.
-- Get course ids:
SELECT @cse := course_id FROM courses WHERE course_name LIKE 'B.Tech - Computer Science%';
SELECT @eee := course_id FROM courses WHERE course_name LIKE 'B.Tech - Electrical%';
SELECT @mech := course_id FROM courses WHERE course_name LIKE 'B.Tech - Mechanical%';

-- CSE subjects
INSERT INTO subjects (subject_code, subject_name, course_id, semester, max_marks) VALUES
('CSE401','Operating Systems', @cse, 4, 100),
('CSE402','Database Systems', @cse, 4, 100),
('CSE403','Computer Networks', @cse, 4, 100),
('CSE404','Software Engineering', @cse, 4, 100),
('MAT404','Discrete Mathematics', @cse, 4, 100),
('ELE401','Microprocessors', @cse, 4, 100);

-- EEE subjects
INSERT INTO subjects (subject_code, subject_name, course_id, semester, max_marks) VALUES
('EEE401','Power Systems', @eee, 4, 100),
('EEE402','Electric Machines II', @eee, 4, 100),
('EEE403','Control Systems', @eee, 4, 100),
('EEE404','Power Electronics', @eee, 4, 100),
('MAT404','Signals & Systems', @eee, 4, 100),
('CSE401','Embedded Systems', @eee, 4, 100);

-- MECH subjects
INSERT INTO subjects (subject_code, subject_name, course_id, semester, max_marks) VALUES
('MECH401','Thermodynamics', @mech, 4, 100),
('MECH402','Theory of Machines', @mech, 4, 100),
('MECH403','Manufacturing Processes', @mech, 4, 100),
('MECH404','Strength of Materials', @mech, 4, 100),
('MAT404','Engineering Mechanics', @mech, 4, 100),
('MECH405','Fluid Mechanics', @mech, 4, 100);


-- Insert 3 students (one per course) - semester 4
INSERT INTO students (student_name, registration_number, roll_number, course_id, semester, academic_year, date_of_birth) VALUES
('Arjun K', 'CSE2025001', '21CSE001', @cse, 4, '2024-25', '2002-02-14'),
('Deepa R', 'EEE2025002', '21EEE002', @eee, 4, '2024-25', '2001-08-06'),
('Manoj S', 'MECH2025003', '21MECH003', @mech, 4, '2024-25', '2002-11-22');

-- Insert results (internal + external + grade) for each student
-- CSE student - mostly passes
INSERT INTO results (student_id, subject_id, internal_marks, external_marks, grade)
SELECT s.student_id, sub.subject_id, vals.internal, vals.external, vals.grade
FROM students s
JOIN (SELECT * FROM subjects WHERE course_id = @cse AND semester = 4) sub ON 1=1
JOIN (
  SELECT 12 AS seq, 22 AS internal, 60 AS external, 'A' AS grade UNION ALL
  SELECT 11, 18, 58, 'A' UNION ALL
  SELECT 10, 14, 62, 'A+' UNION ALL
  SELECT 9, 16, 54, 'B+' UNION ALL
  SELECT 8, 20, 50, 'B' UNION ALL
  SELECT 7, 15, 55, 'A'
) vals ON sub.subject_id IS NOT NULL
JOIN students s2 ON s2.registration_number = 'CSE2025001'
WHERE s.student_id = s2.student_id
LIMIT 6;

-- Simpler: We'll remove above approach and insert explicit values per subject to avoid mismatch
DELETE FROM results WHERE student_id = (SELECT student_id FROM students WHERE registration_number='CSE2025001');
INSERT INTO results (student_id, subject_id, internal_marks, external_marks, grade)
VALUES
((SELECT student_id FROM students WHERE registration_number='CSE2025001'), (SELECT subject_id FROM subjects WHERE course_id=@cse AND subject_code='CSE401' LIMIT 1), 12, 60, 'A'),
((SELECT student_id FROM students WHERE registration_number='CSE2025001'), (SELECT subject_id FROM subjects WHERE course_id=@cse AND subject_code='CSE402' LIMIT 1), 11, 58, 'A'),
((SELECT student_id FROM students WHERE registration_number='CSE2025001'), (SELECT subject_id FROM subjects WHERE course_id=@cse AND subject_code='CSE403' LIMIT 1), 10, 62, 'A+'),
((SELECT student_id FROM students WHERE registration_number='CSE2025001'), (SELECT subject_id FROM subjects WHERE course_id=@cse AND subject_code='CSE404' LIMIT 1), 9, 54, 'B+'),
((SELECT student_id FROM students WHERE registration_number='CSE2025001'), (SELECT subject_id FROM subjects WHERE course_id=@cse AND subject_code='MAT404' LIMIT 1), 8, 50, 'B'),
((SELECT student_id FROM students WHERE registration_number='CSE2025001'), (SELECT subject_id FROM subjects WHERE course_id=@cse AND subject_code='ELE401' LIMIT 1), 7, 55, 'A');

-- EEE student - one low mark to produce a fail in a subject
DELETE FROM results WHERE student_id = (SELECT student_id FROM students WHERE registration_number='EEE2025002');
INSERT INTO results (student_id, subject_id, internal_marks, external_marks, grade)
VALUES
((SELECT student_id FROM students WHERE registration_number='EEE2025002'), (SELECT subject_id FROM subjects WHERE course_id=@eee AND subject_code='EEE401' LIMIT 1), 10, 45, 'B+'),
((SELECT student_id FROM students WHERE registration_number='EEE2025002'), (SELECT subject_id FROM subjects WHERE course_id=@eee AND subject_code='EEE402' LIMIT 1), 9, 42, 'B'),
((SELECT student_id FROM students WHERE registration_number='EEE2025002'), (SELECT subject_id FROM subjects WHERE course_id=@eee AND subject_code='EEE403' LIMIT 1), 8, 40, 'C'),
((SELECT student_id FROM students WHERE registration_number='EEE2025002'), (SELECT subject_id FROM subjects WHERE course_id=@eee AND subject_code='EEE404' LIMIT 1), 7, 18, 'F'), -- fail external
((SELECT student_id FROM students WHERE registration_number='EEE2025002'), (SELECT subject_id FROM subjects WHERE course_id=@eee AND subject_code='MAT404' LIMIT 1), 12, 48, 'A'),
((SELECT student_id FROM students WHERE registration_number='EEE2025002'), (SELECT subject_id FROM subjects WHERE course_id=@eee AND subject_code='CSE401' LIMIT 1), 11, 50, 'A');

-- MECH student - border pass / good performance
DELETE FROM results WHERE student_id = (SELECT student_id FROM students WHERE registration_number='MECH2025003');
INSERT INTO results (student_id, subject_id, internal_marks, external_marks, grade)
VALUES
((SELECT student_id FROM students WHERE registration_number='MECH2025003'), (SELECT subject_id FROM subjects WHERE course_id=@mech AND subject_code='MECH401' LIMIT 1), 14, 65, 'O'),
((SELECT student_id FROM students WHERE registration_number='MECH2025003'), (SELECT subject_id FROM subjects WHERE course_id=@mech AND subject_code='MECH402' LIMIT 1), 12, 60, 'A+'),
((SELECT student_id FROM students WHERE registration_number='MECH2025003'), (SELECT subject_id FROM subjects WHERE course_id=@mech AND subject_code='MECH403' LIMIT 1), 11, 58, 'A'),
((SELECT student_id FROM students WHERE registration_number='MECH2025003'), (SELECT subject_id FROM subjects WHERE course_id=@mech AND subject_code='MECH404' LIMIT 1), 10, 50, 'B+'),
((SELECT student_id FROM students WHERE registration_number='MECH2025003'), (SELECT subject_id FROM subjects WHERE course_id=@mech AND subject_code='MAT404' LIMIT 1), 9, 56, 'A'),
((SELECT student_id FROM students WHERE registration_number='MECH2025003'), (SELECT subject_id FROM subjects WHERE course_id=@mech AND subject_code='MECH405' LIMIT 1), 13, 62, 'A+');

-- End of sample data
