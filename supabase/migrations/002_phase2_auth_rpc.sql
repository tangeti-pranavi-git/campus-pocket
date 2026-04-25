-- Phase-2 auth helper RPC for username/password login
-- Uses existing Phase-1 user table and returns role-safe profile payload.

CREATE OR REPLACE FUNCTION authenticate_portal_user(
  p_username TEXT,
  p_password TEXT
)
RETURNS TABLE (
  user_id BIGINT,
  username TEXT,
  role user_role,
  full_name TEXT,
  school_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.username,
    u.role,
    u.full_name,
    u.school_id
  FROM "user" u
  WHERE u.username = p_username
    AND (
      u.password_hash = crypt(p_password, u.password_hash)
      OR u.password_hash = p_password
    )
  LIMIT 1;
END;
$$;

REVOKE ALL ON FUNCTION authenticate_portal_user(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authenticate_portal_user(TEXT, TEXT) TO anon, authenticated;
