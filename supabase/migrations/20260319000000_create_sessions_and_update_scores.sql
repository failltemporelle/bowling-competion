-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id uuid NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  name text NOT NULL,
  session_number integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS for sessions
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view sessions" ON sessions;
DROP POLICY IF EXISTS "Anyone can create sessions" ON sessions;
DROP POLICY IF EXISTS "Anyone can update sessions" ON sessions;
DROP POLICY IF EXISTS "Anyone can delete sessions" ON sessions;

CREATE POLICY "Anyone can view sessions" ON sessions FOR SELECT USING (true);
CREATE POLICY "Anyone can create sessions" ON sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update sessions" ON sessions FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Anyone can delete sessions" ON sessions FOR DELETE USING (true);

-- Update scores table to use session_id instead of session_number
-- (From previous faulty migrations, drop constraint and column if exist)
ALTER TABLE scores DROP CONSTRAINT IF EXISTS scores_participant_session_unique;
ALTER TABLE scores DROP COLUMN IF EXISTS session_number;

-- Add session_id column to scores
ALTER TABLE scores ADD COLUMN IF NOT EXISTS session_id uuid REFERENCES sessions(id) ON DELETE CASCADE;

-- Create default sessions for existing competitions and link existing scores
DO $$
DECLARE
  comp_record RECORD;
  new_session_id uuid;
BEGIN
  FOR comp_record IN SELECT id FROM competitions LOOP
    -- Insert a default session for each competition
    INSERT INTO sessions (competition_id, name, session_number)
    VALUES (comp_record.id, 'Session 1', 1)
    RETURNING id INTO new_session_id;

    -- Update existing scores for participants in this competition
    -- Since scores don't have competition_id, we join through participants and teams
    UPDATE scores
    SET session_id = new_session_id
    FROM participants p
    JOIN teams t ON t.id = p.team_id
    WHERE scores.participant_id = p.id
      AND t.competition_id = comp_record.id
      AND scores.session_id IS NULL;
  END LOOP;
END $$;

-- Make session_id required now that existing rows are updated
ALTER TABLE scores ALTER COLUMN session_id SET NOT NULL;

-- Add new unique constraint
ALTER TABLE scores DROP CONSTRAINT IF EXISTS scores_participant_session_id_unique;
ALTER TABLE scores ADD CONSTRAINT scores_participant_session_id_unique UNIQUE (participant_id, session_id);
