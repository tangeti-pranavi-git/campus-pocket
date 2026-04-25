-- 006_parent_portal_rls.sql
-- Enable Row Level Security and policies for parent portal tables

-- Announcements: only allow selects for users from the same school
ALTER TABLE IF EXISTS announcements ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS announcements_select_school ON announcements
  FOR SELECT
  USING (
    school_id = (current_setting('jwt.claims.school_id')::int)
  );

-- Holidays: only allow selects for users from the same school
ALTER TABLE IF EXISTS holidays ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS holidays_select_school ON holidays
  FOR SELECT
  USING (
    school_id = (current_setting('jwt.claims.school_id')::int)
  );

-- Messages: parents can only operate on their own messages
ALTER TABLE IF EXISTS messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS messages_parent_access ON messages
  FOR ALL
  USING (
    parent_id = (current_setting('jwt.claims.user_id')::bigint)
  )
  WITH CHECK (
    parent_id = (current_setting('jwt.claims.user_id')::bigint)
  );

-- Class timetable: allow selects for users from the same school (via classroom)
ALTER TABLE IF EXISTS class_timetable ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS class_timetable_select_school ON class_timetable
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classroom c WHERE c.id = class_timetable.classroom_id
      AND c.school_id = (current_setting('jwt.claims.school_id')::int)
    )
  );

-- Ensure public cannot bypass policies
REVOKE ALL ON announcements FROM PUBLIC;
REVOKE ALL ON holidays FROM PUBLIC;
REVOKE ALL ON messages FROM PUBLIC;
REVOKE ALL ON class_timetable FROM PUBLIC;

-- Grant read access to authenticated role (RLS remains enforced)
GRANT SELECT ON announcements, holidays, class_timetable TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON messages TO authenticated;

-- Create helpful indexes
CREATE INDEX IF NOT EXISTS idx_messages_parent_student ON messages(parent_id, student_id);
CREATE INDEX IF NOT EXISTS idx_announcements_school_priority ON announcements(school_id, priority);
CREATE INDEX IF NOT EXISTS idx_holidays_school_date ON holidays(school_id, date);

-- Note: These policies assume JWT claims include `user_id` and `school_id` set by your auth backend.
-- If you authenticate via RPC and store sessions locally, ensure the Supabase JWT includes these claims so policies work as expected.
