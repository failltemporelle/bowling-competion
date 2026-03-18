export interface Competition {
  id: string
  name: string
  date: string
  max_score: number
  created_at: string
}

export interface Team {
  id: string
  competition_id: string
  name: string
  location: string
  created_at: string
}

export interface Participant {
  id: string
  team_id: string
  first_name: string
  last_name: string
  nickname: string
  created_at: string
}

export interface Session {
  id: string
  competition_id: string
  name: string
  session_number: number
  created_at: string
}

export interface Score {
  id: string
  participant_id: string
  session_id: string
  score: number
  created_at: string
}

export interface TeamWithParticipants extends Team {
  participants: (Participant & { scores: Score[] })[]
}

export interface CompetitionWithTeams extends Competition {
  teams: TeamWithParticipants[]
}
