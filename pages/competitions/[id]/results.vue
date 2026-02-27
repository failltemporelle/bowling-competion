<script setup lang="ts">
import type { Competition, Team, Participant, Score } from '~/types/database'

const route = useRoute()
const { $supabase } = useNuxtApp()
const competitionId = route.params.id as string

const competition = ref<Competition | null>(null)
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

const teamResults = ref<TeamResult[]>([])
const participantResults = ref<ParticipantResult[]>([])

const loadCompetition = async () => {
  const { data, error } = await $supabase
    .from('competitions')
    .select('*')
    .eq('id', competitionId)
    .maybeSingle()

  if (error) {
    console.error('Error loading competition:', error)
    return
  }

  competition.value = data
}

const loadResults = async () => {
  const { data: teamsData, error: teamsError } = await $supabase
    .from('teams')
    .select('*')
    .eq('competition_id', competitionId)

  if (teamsError) {
    console.error('Error loading teams:', teamsError)
    return
  }

  const teams = teamsData || []
  const allParticipants: ParticipantResult[] = []
  const teamResultsData: TeamResult[] = []

  for (const team of teams) {
    const { data: participantsData, error: participantsError } = await $supabase
      .from('participants')
      .select('*')
      .eq('team_id', team.id)

    if (participantsError) {
      console.error('Error loading participants:', participantsError)
      continue
    }

    const participants = participantsData || []
    let teamTotalScore = 0

    for (const participant of participants) {
      const { data: scoreData, error: scoreError } = await $supabase
        .from('scores')
        .select('*')
        .eq('participant_id', participant.id)
        .maybeSingle()

      if (!scoreError && scoreData) {
        teamTotalScore += scoreData.score

        allParticipants.push({
          id: participant.id,
          firstName: participant.first_name,
          lastName: participant.last_name,
          nickname: participant.nickname,
          teamName: team.name,
          teamLocation: team.location,
          score: scoreData.score
        })
      }
    }

    teamResultsData.push({
      id: team.id,
      name: team.name,
      location: team.location,
      totalScore: teamTotalScore,
      participantCount: participants.length,
      averageScore: participants.length > 0 ? Math.round(teamTotalScore / participants.length) : 0
    })
  }

  teamResults.value = teamResultsData.sort((a, b) => b.totalScore - a.totalScore)
  participantResults.value = allParticipants.sort((a, b) => b.score - a.score)
}

const topTeam = computed(() => {
  return teamResults.value.length > 0 ? teamResults.value[0] : null
})

const topParticipant = computed(() => {
  return participantResults.value.length > 0 ? participantResults.value[0] : null
})

const totalPoints = computed(() => {
  return teamResults.value.reduce((sum, team) => sum + team.totalScore, 0)
})

onMounted(() => {
  loadCompetition()
  loadResults()
})
</script>

<template>
  <div class="px-4 sm:px-0">
    <div class="mb-6">
      <NuxtLink
        to="/"
        class="btn btn-ghost btn-sm"
      >
        <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Retour aux compétitions
      </NuxtLink>
    </div>

    <div v-if="competition" class="mb-6">
      <h1 class="text-3xl font-bold">Dashboard - {{ competition.name }}</h1>
      <p class="mt-2 text-sm opacity-70">
        {{ new Date(competition.date).toLocaleDateString('fr-FR') }}
      </p>
    </div>

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
        <div class="stat-title">Points Marqués</div>
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
      <div v-if="teamResults.length === 0" class="flex flex-col items-center justify-center py-12 text-base-content/50">
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
              <th class="text-right">Score total</th>
              <th class="text-right">Moyenne</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(team, index) in teamResults"
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
      <div v-if="participantResults.length === 0" class="flex flex-col items-center justify-center py-12 text-base-content/50">
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
              v-for="(participant, index) in participantResults"
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
</template>
