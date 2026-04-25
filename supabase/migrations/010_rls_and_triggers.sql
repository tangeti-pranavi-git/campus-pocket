-- 1. Re-enable RLS for safety
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_tasks ENABLE ROW LEVEL SECURITY;

-- 2. Clean up old policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Students can view and update their own volunteer tasks" ON public.volunteer_tasks;

-- 3. Add Proper Policies (Using auth.uid() check)
CREATE POLICY "Allow individual read" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Allow individual update" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Allow student task access" ON public.volunteer_tasks
    FOR ALL USING (auth.uid() = student_id);

-- 4. PROPER BACKEND SYNC (The Trigger)
-- This ensures that whenever a new user is created/updated in Auth, 
-- they automatically appear in your public.users table.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Student'), 
    'student'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
