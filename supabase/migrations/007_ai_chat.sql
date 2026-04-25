-- AI Chat Logs table (Optional but requested)
CREATE TABLE IF NOT EXISTS ai_chat_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    query TEXT NOT NULL,
    response TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for ai_chat_logs
ALTER TABLE IF EXISTS ai_chat_logs ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their own chat logs
CREATE POLICY IF NOT EXISTS ai_chat_logs_select ON ai_chat_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS ai_chat_logs_insert ON ai_chat_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT ON ai_chat_logs TO authenticated;
