-- Ajouter la colonne session_number (par défaut 1 pour les scores existants)
ALTER TABLE scores ADD COLUMN IF NOT EXISTS session_number integer NOT NULL DEFAULT 1;

-- Supprimer l'ancienne contrainte UNIQUE sur participant_id qui empêchait d'avoir plusieurs scores
ALTER TABLE scores DROP CONSTRAINT IF EXISTS scores_participant_id_key;

-- Ajouter une nouvelle contrainte pour qu'un participant n'ait qu'un seul score par session
ALTER TABLE scores ADD CONSTRAINT scores_participant_session_unique UNIQUE (participant_id, session_number);
