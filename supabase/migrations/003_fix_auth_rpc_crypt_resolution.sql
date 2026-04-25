-- Fix Phase-2 auth RPC for environments where crypt() is not globally resolvable.
-- Uses extensions.crypt when present, otherwise falls back to plain-text check.

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
DECLARE
  has_extensions_crypt BOOLEAN;
BEGIN
  SELECT to_regprocedure('extensions.crypt(text,text)') IS NOT NULL
    INTO has_extensions_crypt;

  IF has_extensions_crypt THEN
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
        u.password_hash = p_password
        OR u.password_hash = extensions.crypt(p_password, u.password_hash)
      )
    LIMIT 1;

    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    u.username,
    u.role,
    u.full_name,
    u.school_id
  FROM "user" u
  WHERE u.username = p_username
    AND u.password_hash = p_password
  LIMIT 1;
END;
$$;

REVOKE ALL ON FUNCTION authenticate_portal_user(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION authenticate_portal_user(TEXT, TEXT) TO anon, authenticated;
