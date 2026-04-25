-- Campus Pocket Phase-1 seed data
-- Idempotent seed script

-- Users: 2 parents + 4 students across 2 schools
INSERT INTO "user" (id, username, password_hash, role, full_name, school_id)
VALUES
  (1, 'lakshmi.parent', 'Campus@123', 'parent', 'Lakshmi', 1),
  (2, 'ramesh.parent', 'Campus@123', 'parent', 'Ramesh', 2),
  (3, 'rahul.student', 'Campus@123', 'student', 'Rahul', 1),
  (4, 'priya.student', 'Campus@123', 'student', 'Priya', 1),
  (5, 'kiran.student', 'Campus@123', 'student', 'Kiran', 2),
  (6, 'sneha.student', 'Campus@123', 'student', 'Sneha', 2)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  password_hash = EXCLUDED.password_hash,
  role = EXCLUDED.role,
  full_name = EXCLUDED.full_name,
  school_id = EXCLUDED.school_id;

SELECT setval(pg_get_serial_sequence('"user"', 'id'), GREATEST((SELECT MAX(id) FROM "user"), 1), true);

-- Parent-child mapping
INSERT INTO parent_student_link (id, parent_id, student_id)
VALUES
  (1, 1, 3),
  (2, 1, 4),
  (3, 2, 5),
  (4, 2, 6)
ON CONFLICT (id) DO UPDATE SET
  parent_id = EXCLUDED.parent_id,
  student_id = EXCLUDED.student_id;

SELECT setval(pg_get_serial_sequence('parent_student_link', 'id'), GREATEST((SELECT MAX(id) FROM parent_student_link), 1), true);

-- Classrooms in two schools
INSERT INTO classroom (id, name, school_id)
VALUES
  (1, '10th Grade Math', 1),
  (2, 'Science Batch A', 1),
  (3, 'English Advanced', 2)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  school_id = EXCLUDED.school_id;

SELECT setval(pg_get_serial_sequence('classroom', 'id'), GREATEST((SELECT MAX(id) FROM classroom), 1), true);

-- Classroom memberships (students only, same school)
INSERT INTO classroom_membership (id, classroom_id, user_id, role)
VALUES
  (1, 1, 3, 'student'),
  (2, 1, 4, 'student'),
  (3, 2, 3, 'student'),
  (4, 2, 4, 'student'),
  (5, 3, 5, 'student'),
  (6, 3, 6, 'student')
ON CONFLICT (id) DO UPDATE SET
  classroom_id = EXCLUDED.classroom_id,
  user_id = EXCLUDED.user_id,
  role = EXCLUDED.role;

SELECT setval(pg_get_serial_sequence('classroom_membership', 'id'), GREATEST((SELECT MAX(id) FROM classroom_membership), 1), true);

-- Sessions for each classroom
INSERT INTO class_session (id, classroom_id, session_date, topic)
VALUES
  (1, 1, '2026-04-01', 'Linear Equations Review'),
  (2, 1, '2026-04-03', 'Quadratic Intro'),
  (3, 1, '2026-04-05', 'Polynomials Practice'),
  (4, 2, '2026-04-02', 'Cell Structure Basics'),
  (5, 2, '2026-04-04', 'Plant Physiology'),
  (6, 2, '2026-04-06', 'Respiration Lab Prep'),
  (7, 3, '2026-04-01', 'Essay Structure'),
  (8, 3, '2026-04-03', 'Advanced Vocabulary'),
  (9, 3, '2026-04-05', 'Poetry Analysis'),
  (10, 1, '2026-04-08', 'Factorization Drill'),
  (11, 2, '2026-04-08', 'Human Body Systems'),
  (12, 3, '2026-04-08', 'Comprehension Workshop')
ON CONFLICT (id) DO UPDATE SET
  classroom_id = EXCLUDED.classroom_id,
  session_date = EXCLUDED.session_date,
  topic = EXCLUDED.topic;

SELECT setval(pg_get_serial_sequence('class_session', 'id'), GREATEST((SELECT MAX(id) FROM class_session), 1), true);

-- Attendance (24 rows)
INSERT INTO attendance (id, student_id, session_id, status)
VALUES
  (1, 3, 1, 'PRESENT'),
  (2, 4, 1, 'LATE'),
  (3, 3, 2, 'PRESENT'),
  (4, 4, 2, 'PRESENT'),
  (5, 3, 3, 'ABSENT'),
  (6, 4, 3, 'PRESENT'),
  (7, 3, 4, 'PRESENT'),
  (8, 4, 4, 'PRESENT'),
  (9, 3, 5, 'LATE'),
  (10, 4, 5, 'PRESENT'),
  (11, 3, 6, 'PRESENT'),
  (12, 4, 6, 'ABSENT'),
  (13, 5, 7, 'PRESENT'),
  (14, 6, 7, 'PRESENT'),
  (15, 5, 8, 'LATE'),
  (16, 6, 8, 'ABSENT'),
  (17, 5, 9, 'PRESENT'),
  (18, 6, 9, 'PRESENT'),
  (19, 3, 10, 'PRESENT'),
  (20, 4, 10, 'LATE'),
  (21, 3, 11, 'PRESENT'),
  (22, 4, 11, 'PRESENT'),
  (23, 5, 12, 'PRESENT'),
  (24, 6, 12, 'LATE')
ON CONFLICT (id) DO UPDATE SET
  student_id = EXCLUDED.student_id,
  session_id = EXCLUDED.session_id,
  status = EXCLUDED.status;

SELECT setval(pg_get_serial_sequence('attendance', 'id'), GREATEST((SELECT MAX(id) FROM attendance), 1), true);

-- Assignments
INSERT INTO assignment (id, classroom_id, title, total_marks, due_date)
VALUES
  (1, 1, 'Algebra Worksheet', 100, '2026-04-10'),
  (2, 1, 'Quadratic Quiz', 50, '2026-04-15'),
  (3, 2, 'Biology Diagram Sheet', 75, '2026-04-12'),
  (4, 2, 'Science Lab Report', 100, '2026-04-18'),
  (5, 3, 'Essay Draft', 100, '2026-04-11'),
  (6, 3, 'Poetry Critique', 80, '2026-04-17')
ON CONFLICT (id) DO UPDATE SET
  classroom_id = EXCLUDED.classroom_id,
  title = EXCLUDED.title,
  total_marks = EXCLUDED.total_marks,
  due_date = EXCLUDED.due_date;

SELECT setval(pg_get_serial_sequence('assignment', 'id'), GREATEST((SELECT MAX(id) FROM assignment), 1), true);

-- Assignment submissions (10 rows)
INSERT INTO assignment_submission (id, assignment_id, user_id, score, total)
VALUES
  (1, 1, 3, 88, 100),
  (2, 1, 4, 92, 100),
  (3, 2, 3, 41, 50),
  (4, 2, 4, 46, 50),
  (5, 3, 3, 67, 75),
  (6, 3, 4, 70, 75),
  (7, 5, 5, 84, 100),
  (8, 5, 6, 78, 100),
  (9, 6, 5, 66, 80),
  (10, 6, 6, 72, 80)
ON CONFLICT (id) DO UPDATE SET
  assignment_id = EXCLUDED.assignment_id,
  user_id = EXCLUDED.user_id,
  score = EXCLUDED.score,
  total = EXCLUDED.total;

SELECT setval(pg_get_serial_sequence('assignment_submission', 'id'), GREATEST((SELECT MAX(id) FROM assignment_submission), 1), true);

-- Fees (6 rows)
INSERT INTO fees (id, student_id, amount, due_date, status, paid_on)
VALUES
  (1, 3, 15000.00, '2026-04-05', 'PAID', '2026-04-04'),
  (2, 4, 15000.00, '2026-04-05', 'PENDING', NULL),
  (3, 5, 18000.00, '2026-04-05', 'OVERDUE', NULL),
  (4, 6, 18000.00, '2026-04-05', 'PAID', '2026-04-03'),
  (5, 3, 5000.00, '2026-05-05', 'PENDING', NULL),
  (6, 5, 6000.00, '2026-05-05', 'PENDING', NULL)
ON CONFLICT (id) DO UPDATE SET
  student_id = EXCLUDED.student_id,
  amount = EXCLUDED.amount,
  due_date = EXCLUDED.due_date,
  status = EXCLUDED.status,
  paid_on = EXCLUDED.paid_on;

SELECT setval(pg_get_serial_sequence('fees', 'id'), GREATEST((SELECT MAX(id) FROM fees), 1), true);
