-- Phase 5: Advanced Reporting and Analysis

-- Add exam_type and subject to assignment
ALTER TABLE assignment 
ADD COLUMN IF NOT EXISTS exam_type TEXT DEFAULT 'Class Assessment',
ADD COLUMN IF NOT EXISTS subject TEXT DEFAULT 'General';

-- Add transport and unread_notices to parent_student_link or user? Let's just use existing tables.
-- Unread notices = announcements that haven't been read? We don't have a read-receipt table for announcements.
-- We will simulate it in the frontend or just count announcements created in the last 7 days.

-- Seed some new exams to test the dropdown
DO $$
DECLARE
  cid BIGINT;
BEGIN
  SELECT id INTO cid FROM classroom LIMIT 1;
  IF cid IS NOT NULL THEN
    -- English
    INSERT INTO assignment (classroom_id, title, total_marks, due_date, exam_type, subject) VALUES
    (cid, 'English Quarterly', 100, CURRENT_DATE - INTERVAL '60 days', 'Quarterly Exam', 'English'),
    (cid, 'English Half-Yearly', 100, CURRENT_DATE - INTERVAL '30 days', 'Half-Yearly', 'English');
    
    -- Math
    INSERT INTO assignment (classroom_id, title, total_marks, due_date, exam_type, subject) VALUES
    (cid, 'Math Quarterly', 100, CURRENT_DATE - INTERVAL '60 days', 'Quarterly Exam', 'Mathematics'),
    (cid, 'Math Half-Yearly', 100, CURRENT_DATE - INTERVAL '30 days', 'Half-Yearly', 'Mathematics');
    
    -- Science
    INSERT INTO assignment (classroom_id, title, total_marks, due_date, exam_type, subject) VALUES
    (cid, 'Science Quarterly', 100, CURRENT_DATE - INTERVAL '60 days', 'Quarterly Exam', 'Science'),
    (cid, 'Science Half-Yearly', 100, CURRENT_DATE - INTERVAL '30 days', 'Half-Yearly', 'Science');
    
    -- Social
    INSERT INTO assignment (classroom_id, title, total_marks, due_date, exam_type, subject) VALUES
    (cid, 'Social Quarterly', 100, CURRENT_DATE - INTERVAL '60 days', 'Quarterly Exam', 'Social Studies'),
    (cid, 'Social Half-Yearly', 100, CURRENT_DATE - INTERVAL '30 days', 'Half-Yearly', 'Social Studies');
    
    -- Hindi
    INSERT INTO assignment (classroom_id, title, total_marks, due_date, exam_type, subject) VALUES
    (cid, 'Hindi Quarterly', 100, CURRENT_DATE - INTERVAL '60 days', 'Quarterly Exam', 'Hindi'),
    (cid, 'Hindi Half-Yearly', 100, CURRENT_DATE - INTERVAL '30 days', 'Half-Yearly', 'Hindi');
  END IF;
END $$;

-- Seed submissions for the new exams
DO $$
DECLARE
  stid BIGINT;
  ass_rec RECORD;
BEGIN
  -- Get first student
  SELECT id INTO stid FROM "user" WHERE role = 'student' LIMIT 1;
  
  IF stid IS NOT NULL THEN
    FOR ass_rec IN SELECT id, total_marks, subject, exam_type FROM assignment WHERE exam_type IN ('Quarterly Exam', 'Half-Yearly')
    LOOP
      -- generate random score between 40 and 95
      INSERT INTO assignment_submission (assignment_id, user_id, score, total)
      VALUES (ass_rec.id, stid, floor(random() * (95 - 40 + 1) + 40), ass_rec.total_marks)
      ON CONFLICT (assignment_id, user_id) DO UPDATE SET score = EXCLUDED.score;
    END LOOP;
  END IF;
END $$;
