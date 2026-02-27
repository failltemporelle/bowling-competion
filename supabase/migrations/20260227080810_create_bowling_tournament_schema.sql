/*
  # Bowling Tournament Management Schema

  ## Overview
  This migration creates the complete database schema for managing bowling tournaments,
  including competitions, teams, participants, and their scores.

  ## New Tables

  ### 1. `competitions`
  Stores bowling competition/tournament information
  - `id` (uuid, primary key) - Unique identifier
  - `name` (text) - Competition name
  - `date` (date) - Competition date
  - `max_score` (integer) - Maximum score possible
  - `created_at` (timestamptz) - Record creation timestamp

  ### 2. `teams`
  Stores team information for each competition
  - `id` (uuid, primary key) - Unique identifier
  - `competition_id` (uuid, foreign key) - Reference to competition
  - `name` (text) - Team name
  - `location` (text) - Team location
  - `created_at` (timestamptz) - Record creation timestamp

  ### 3. `participants`
  Stores participant information for each team
  - `id` (uuid, primary key) - Unique identifier
  - `team_id` (uuid, foreign key) - Reference to team
  - `first_name` (text) - Participant first name
  - `last_name` (text) - Participant last name
  - `nickname` (text) - Participant nickname
  - `created_at` (timestamptz) - Record creation timestamp

  ### 4. `scores`
  Stores scores for each participant
  - `id` (uuid, primary key) - Unique identifier
  - `participant_id` (uuid, foreign key) - Reference to participant
  - `score` (integer) - Score achieved
  - `created_at` (timestamptz) - Record creation timestamp

  ## Security
  - RLS enabled on all tables
  - Public read access for all tables (tournament results are public)
  - No write restrictions (simplified for tournament management)

  ## Notes
  1. All tables use UUID primary keys for better scalability
  2. Foreign keys ensure data integrity
  3. Timestamps track when records are created
  4. Cascading deletes ensure cleanup when parent records are removed
*/

-- Create competitions table
CREATE TABLE IF NOT EXISTS competitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  date date NOT NULL,
  max_score integer NOT NULL DEFAULT 300,
  created_at timestamptz DEFAULT now()
);

-- Create teams table
CREATE TABLE IF NOT EXISTS teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id uuid NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  name text NOT NULL,
  location text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create participants table
CREATE TABLE IF NOT EXISTS participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id uuid NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  first_name text NOT NULL,
  last_name text NOT NULL,
  nickname text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create scores table
CREATE TABLE IF NOT EXISTS scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_id uuid NOT NULL REFERENCES participants(id) ON DELETE CASCADE,
  score integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(participant_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_teams_competition ON teams(competition_id);
CREATE INDEX IF NOT EXISTS idx_participants_team ON participants(team_id);
CREATE INDEX IF NOT EXISTS idx_scores_participant ON scores(participant_id);

-- Enable Row Level Security
ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;

-- RLS Policies - Public read access for tournament data
CREATE POLICY "Anyone can view competitions"
  ON competitions FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create competitions"
  ON competitions FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update competitions"
  ON competitions FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete competitions"
  ON competitions FOR DELETE
  USING (true);

CREATE POLICY "Anyone can view teams"
  ON teams FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create teams"
  ON teams FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update teams"
  ON teams FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete teams"
  ON teams FOR DELETE
  USING (true);

CREATE POLICY "Anyone can view participants"
  ON participants FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create participants"
  ON participants FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update participants"
  ON participants FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete participants"
  ON participants FOR DELETE
  USING (true);

CREATE POLICY "Anyone can view scores"
  ON scores FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create scores"
  ON scores FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update scores"
  ON scores FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete scores"
  ON scores FOR DELETE
  USING (true);