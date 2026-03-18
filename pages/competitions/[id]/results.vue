<script setup lang="ts">
import type { Competition, Team, Participant, Score, Session } from '~/types/database'

const route = useRoute()
const { $supabase } = useNuxtApp()
const competitionId = route.params.id as string

const competition = ref<Competition | null>(null)
const sessions = ref<Session[]>([])
const selectedSessionId = ref<string | null>(null)
const viewMode = ref<'teams' | 'participants'>('teams')

interface TeamResult {
  id: string
  name: string
  location: string
  totalScore: number
  participantCount: number
  averageScore: number
}

interface ParticipantResult {
  id: string
  firstName: string
  lastName: string
  nickname: string
  teamName: string
  teamLocation: string
  score: number
}

// Stores all raw data
const rawTeams = ref<Team[]>([])
const rawParticipants = ref<Participant[]>([])
const rawScores = ref<Score[]>([])

const loadCompetition = async () => {
  const { data, error } = await $supabase
    .from('competitions')
    .select('*')
    .eq('id', competitionId)
    .maybeSingle()

  if (!error && data) {
    competition.value = data
  }
}

const loadSessions = async () => {
  const { data, error } = await $supabase
    .from('sessions')
    .select('*')
    .eq('competition_id', competitionId)
    .order('session_number')

  if (!error && data) {
    sessions.value = data
    if (data.length > 0 && !selectedSessionId.value) {
      selectedSessionId.value = data[0].id
    }
  }
}

const loadAllData = async () => {
  const [teamsRes, participantsRes, scoresRes] = await Promise.all([
    $supabase.from('teams').select('*').eq('competition_id', competitionId),
    // We can't filter participants by competition directly, so we fetch all 
    // and filter them in memory or join. Since dataset is small we can do multiple queries or a join.
    $supabase.from('participants').select('*, teams!inner(competition_id)').eq('teams.competition_id', competitionId),
    $supabase.from('scores').select('*, sessions!inner(competition_id)').eq('sessions.competition_id', competitionId)
  ])

  if (teamsRes.data) rawTeams.value = teamsRes.data
  if (participantsRes.data) rawParticipants.value = participantsRes.data.map(p => ({
    id: p.id,
    team_id: p.team_id,
    first_name: p.first_name,
    last_name: p.last_name,
    nickname: p.nickname,
    created_at: p.created_at
  })) as Participant[]
  if (scoresRes.data) rawScores.value = scoresRes.data.map(s => ({
    id: s.id,
    participant_id: s.participant_id,
    session_id: s.session_id,
    score: s.score,
    created_at: s.created_at
  })) as Score[]
}

const filteredTeamResults = computed<TeamResult[]>(() => {
  if (!selectedSessionId.value) return []

  const results: TeamResult[] = []
  
  for (const team of rawTeams.value) {
    const teamParticipants = rawParticipants.value.filter(p => p.team_id === team.id)
    let teamTotalScore = 0
    let validScoresCount = 0

    for (const participant of teamParticipants) {
      const score = rawScores.value.find(s => s.participant_id === participant.id && s.session_id === selectedSessionId.value)
      if (score) {
        teamTotalScore += score.score
        validScoresCount++
      }
    }

    if (teamParticipants.length > 0) {
      results.push({
        id: team.id,
        name: team.name,
        location: team.location,
        totalScore: teamTotalScore,
        participantCount: teamParticipants.length,
        averageScore: validScoresCount > 0 ? Math.round(teamTotalScore / validScoresCount) : 0
      })
    }
  }

  return results.sort((a, b) => b.totalScore - a.totalScore)
})

const filteredParticipantResults = computed<ParticipantResult[]>(() => {
  if (!selectedSessionId.value) return []

  const results: ParticipantResult[] = []

  for (const participant of rawParticipants.value) {
    const score = rawScores.value.find(s => s.participant_id === participant.id && s.session_id === selectedSessionId.value)
    if (score) {
      const team = rawTeams.value.find(t => t.id === participant.team_id)
      results.push({
        id: participant.id,
        firstName: participant.first_name,
        lastName: participant.last_name,
        nickname: participant.nickname,
        teamName: team?.name || 'Inconnue',
        teamLocation: team?.location || '',
        score: score.score
      })
    }
  }

  return results.sort((a, b) => b.score - a.score)
})

const topTeam = computed(() => {
  return filteredTeamResults.value.length > 0 ? filteredTeamResults.value[0] : null
})

const topParticipant = computed(() => {
  return filteredParticipantResults.value.length > 0 ? filteredParticipantResults.value[0] : null
})

const totalPoints = computed(() => {
  return filteredTeamResults.value.reduce((sum, team) => sum + team.totalScore, 0)
})

onMounted(async () => {
  await loadCompetition()
  await loadSessions()
  await loadAllData()
})
</script>

<template>
  <div class="px-4 sm:px-0">
    <div class="mb-6">
      <NuxtLink
        to="/"
        class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
      >
        <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Retour aux compétitions
      </NuxtLink>
    </div>

    <div v-if="competition" class="mb-6 flex justify-between items-end">
      <div>
        <h1 class="text-3xl font-bold">Dashboard - {{ competition.name }}</h1>
        <p class="mt-2 text-sm opacity-70">
          {{ new Date(competition.date).toLocaleDateString('fr-FR') }}
        </p>
      </div>

      <!-- Select Session Dropdown -->
      <div v-if="sessions.length > 0" class="flex flex-col">
        <label class="text-sm font-medium text-gray-700 mb-1">Sélectionner une Session</label>
        <select
          v-model="selectedSessionId"
          class="block w-48 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
        >
          <option v-for="session in sessions" :key="session.id" :value="session.id">
            {{ session.name }}
          </option>
        </select>
      </div>
    </div>

    <div v-if="sessions.length === 0" class="text-center py-12 bg-white rounded-lg shadow">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">Aucune session</h3>
      <p class="mt-1 text-sm text-gray-500">Allez dans la page de gestion pour ajouter une session.</p>
    </div>

    <div v-else-if="!selectedSessionId" class="text-center py-12 bg-white rounded-lg shadow">
      <p class="text-gray-500">Veuillez sélectionner une session.</p>
    </div>

    <div v-else>
      <!-- KPI Cards using DaisyUI stats -->
      <div class="stats stats-vertical lg:stats-horizontal shadow w-full mb-8">
        <!-- Meilleure Équipe -->
        <div class="stat">
          <div class="stat-figure text-warning">
            <svg class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <div class="stat-title">Meilleure Équipe</div>
          <div class="stat-value text-xl lg:text-3xl text-warning truncate">
            {{ topTeam ? topTeam.name : '-' }}
          </div>
          <div class="stat-desc font-medium">{{ topTeam ? topTeam.totalScore : 0 }} points</div>
        </div>

        <!-- Meilleur Participant -->
        <div class="stat">
          <div class="stat-figure text-info">
            <svg class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <div class="stat-title">Meilleur Participant</div>
          <div class="stat-value text-xl lg:text-3xl text-info truncate" :title="topParticipant ? `${topParticipant.firstName} ${topParticipant.lastName}` : ''">
            {{ topParticipant ? `${topParticipant.firstName} ${topParticipant.lastName}` : '-' }}
          </div>
          <div class="stat-desc font-medium truncate" :title="topParticipant?.teamName">
            {{ topParticipant ? `${topParticipant.score} pts - ${topParticipant.teamName}` : '0 points' }}
          </div>
        </div>

        <!-- Total Points -->
        <div class="stat">
          <div class="stat-figure text-success">
            <svg class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
            </svg>
          </div>
          <div class="stat-title">Points Globaux (Session)</div>
          <div class="stat-value text-xl lg:text-3xl text-success">{{ totalPoints }}</div>
          <div class="stat-desc font-medium">Sur toutes les équipes</div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="mb-6">
        <div role="tablist" class="tabs tabs-bordered">
          <button
            @click="viewMode = 'teams'"
            role="tab"
            :class="['tab', 'tab-lg', viewMode === 'teams' ? 'tab-active font-bold' : '']"
          >
            Classement par équipe
          </button>
          <button
            @click="viewMode = 'participants'"
            role="tab"
            :class="['tab', 'tab-lg', viewMode === 'participants' ? 'tab-active font-bold' : '']"
          >
            Classement par participant
          </button>
        </div>
      </div>

      <div v-if="viewMode === 'teams'">
        <div v-if="filteredTeamResults.length === 0" class="flex flex-col items-center justify-center py-12 text-base-content/50">
          <svg class="h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
          <h3 class="text-lg font-medium text-base-content">Aucun résultat</h3>
          <p class="mt-1 text-sm">
            Les résultats apparaîtront une fois les scores enregistrés.
          </p>
        </div>

        <div v-else class="overflow-x-auto bg-base-100 shadow rounded-lg mb-8">
          <table class="table table-zebra table-pin-rows w-full">
            <thead class="bg-base-200">
              <tr>
                <th>Position</th>
                <th>Équipe</th>
                <th>Localisation</th>
                <th class="text-right">Participants</th>
                <th class="text-right">Score de session</th>
                <th class="text-right">Moyenne / joueur</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(team, index) in filteredTeamResults"
                :key="team.id"
                :class="[
                  index === 0 ? 'bg-warning/20' : '',
                  index === 1 ? 'bg-base-200/50' : '',
                  index === 2 ? 'bg-orange-500/20' : ''
                ]"
              >
                <td>
                  <span
                    v-if="index < 3"
                    class="badge badge-lg font-bold"
                    :class="[
                      index === 0 ? 'badge-warning' : '',
                      index === 1 ? 'badge-ghost' : '',
                      index === 2 ? 'bg-orange-400 text-white border-orange-400' : ''
                    ]"
                  >
                    {{ index + 1 }}
                  </span>
                  <span v-else class="font-medium px-2">
                    {{ index + 1 }}
                  </span>
                </td>
                <td class="font-medium text-base">{{ team.name }}</td>
                <td class="opacity-80">{{ team.location }}</td>
                <td class="text-right">{{ team.participantCount }}</td>
                <td class="text-right font-bold text-lg">{{ team.totalScore }}</td>
                <td class="text-right opacity-80">{{ team.averageScore }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div v-if="viewMode === 'participants'">
        <div v-if="filteredParticipantResults.length === 0" class="flex flex-col items-center justify-center py-12 text-base-content/50">
          <svg class="h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          <h3 class="text-lg font-medium text-base-content">Aucun résultat</h3>
          <p class="mt-1 text-sm">
            Les résultats apparaîtront une fois les scores enregistrés.
          </p>
        </div>

        <div v-else class="overflow-x-auto bg-base-100 shadow rounded-lg mb-8">
          <table class="table table-zebra table-pin-rows w-full">
            <thead class="bg-base-200">
              <tr>
                <th>Position</th>
                <th>Participant</th>
                <th>Surnom</th>
                <th>Équipe</th>
                <th class="text-right">Score</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(participant, index) in filteredParticipantResults"
                :key="participant.id"
                :class="[
                  index === 0 ? 'bg-warning/20' : '',
                  index === 1 ? 'bg-base-200/50' : '',
                  index === 2 ? 'bg-orange-500/20' : ''
                ]"
              >
                <td>
                  <span
                    v-if="index < 3"
                    class="badge badge-lg font-bold"
                    :class="[
                      index === 0 ? 'badge-warning' : '',
                      index === 1 ? 'badge-ghost' : '',
                      index === 2 ? 'bg-orange-400 text-white border-orange-400' : ''
                    ]"
                  >
                    {{ index + 1 }}
                 </span>
                  <span v-else class="font-medium px-2">
                    {{ index + 1 }}
                  </span>
                </td>
                <td class="font-medium text-base">
                  {{ participant.firstName }} {{ participant.lastName }}
                </td>
                <td class="opacity-80">{{ participant.nickname }}</td>
                <td>
                  <div class="font-medium">{{ participant.teamName }}</div>
                  <div class="text-xs opacity-70">{{ participant.teamLocation }}</div>
                </td>
                <td class="text-right font-bold text-lg">{{ participant.score }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

