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
        class="inline-flex items-center text-sm text-blue-600 hover:text-blue-800 transition-colors"
      >
        <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Retour aux compétitions
      </NuxtLink>
    </div>

    <div v-if="competition" class="mb-6">
      <h1 class="text-3xl font-bold text-gray-900">Résultats - {{ competition.name }}</h1>
      <p class="mt-2 text-sm text-gray-600">
        {{ new Date(competition.date).toLocaleDateString('fr-FR') }}
      </p>
    </div>

    <div class="mb-6">
      <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8">
          <button
            @click="viewMode = 'teams'"
            :class="[
              viewMode === 'teams'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
              'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors'
            ]"
          >
            Classement par équipe
          </button>
          <button
            @click="viewMode = 'participants'"
            :class="[
              viewMode === 'participants'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
              'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors'
            ]"
          >
            Classement par participant
          </button>
        </nav>
      </div>
    </div>

    <div v-if="viewMode === 'teams'">
      <div v-if="teamResults.length === 0" class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">Aucun résultat</h3>
        <p class="mt-1 text-sm text-gray-500">
          Les résultats apparaîtront une fois les scores enregistrés.
        </p>
      </div>

      <div v-else class="bg-white shadow overflow-hidden rounded-lg">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Position
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Équipe
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Localisation
              </th>
              <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Participants
              </th>
              <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Score total
              </th>
              <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Moyenne
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr
              v-for="(team, index) in teamResults"
              :key="team.id"
              :class="[
                index === 0 ? 'bg-yellow-50' : '',
                index === 1 ? 'bg-gray-50' : '',
                index === 2 ? 'bg-orange-50' : ''
              ]"
            >
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <span
                    v-if="index < 3"
                    class="inline-flex items-center justify-center h-8 w-8 rounded-full text-sm font-bold"
                    :class="[
                      index === 0 ? 'bg-yellow-400 text-yellow-900' : '',
                      index === 1 ? 'bg-gray-300 text-gray-900' : '',
                      index === 2 ? 'bg-orange-400 text-orange-900' : ''
                    ]"
                  >
                    {{ index + 1 }}
                  </span>
                  <span v-else class="text-sm font-medium text-gray-900">
                    {{ index + 1 }}
                  </span>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900">{{ team.name }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-500">{{ team.location }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="text-sm text-gray-900">{{ team.participantCount }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="text-sm font-semibold text-gray-900">{{ team.totalScore }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="text-sm text-gray-500">{{ team.averageScore }}</div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="viewMode === 'participants'">
      <div v-if="participantResults.length === 0" class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">Aucun résultat</h3>
        <p class="mt-1 text-sm text-gray-500">
          Les résultats apparaîtront une fois les scores enregistrés.
        </p>
      </div>

      <div v-else class="bg-white shadow overflow-hidden rounded-lg">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Position
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Participant
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Surnom
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Équipe
              </th>
              <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Score
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr
              v-for="(participant, index) in participantResults"
              :key="participant.id"
              :class="[
                index === 0 ? 'bg-yellow-50' : '',
                index === 1 ? 'bg-gray-50' : '',
                index === 2 ? 'bg-orange-50' : ''
              ]"
            >
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <span
                    v-if="index < 3"
                    class="inline-flex items-center justify-center h-8 w-8 rounded-full text-sm font-bold"
                    :class="[
                      index === 0 ? 'bg-yellow-400 text-yellow-900' : '',
                      index === 1 ? 'bg-gray-300 text-gray-900' : '',
                      index === 2 ? 'bg-orange-400 text-orange-900' : ''
                    ]"
                  >
                    {{ index + 1 }}
                  </span>
                  <span v-else class="text-sm font-medium text-gray-900">
                    {{ index + 1 }}
                  </span>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900">
                  {{ participant.firstName }} {{ participant.lastName }}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-500">{{ participant.nickname }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-900">{{ participant.teamName }}</div>
                <div class="text-xs text-gray-500">{{ participant.teamLocation }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="text-sm font-semibold text-gray-900">{{ participant.score }}</div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
