<script setup lang="ts">
import type { Competition, Team, Participant, Score, Session } from '~/types/database'

const route = useRoute()
const { $supabase } = useNuxtApp()
const competitionId = route.params.id as string

const competition = ref<Competition | null>(null)
const teams = ref<(Team & { participants: (Participant & { scores: Score[] })[] })[]>([])
const sessions = ref<Session[]>([])
const showTeamForm = ref(false)
const showParticipantForm = ref<string | null>(null)

const newTeam = ref({
  name: '',
  location: ''
})

const newParticipant = ref({
  first_name: '',
  last_name: '',
  nickname: ''
})

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

const loadSessions = async () => {
  const { data, error } = await $supabase
    .from('sessions')
    .select('*')
    .eq('competition_id', competitionId)
    .order('session_number')

  if (!error) {
    sessions.value = data || []
  }
}

const loadTeams = async () => {
  const { data: teamsData, error: teamsError } = await $supabase
    .from('teams')
    .select('*')
    .eq('competition_id', competitionId)
    .order('name')

  if (teamsError) {
    console.error('Error loading teams:', teamsError)
    return
  }

  const teamsWithParticipants = await Promise.all(
    (teamsData || []).map(async (team) => {
      const { data: participantsData, error: participantsError } = await $supabase
        .from('participants')
        .select('*')
        .eq('team_id', team.id)
        .order('last_name')

      if (participantsError) {
        console.error('Error loading participants:', participantsError)
        return { ...team, participants: [] }
      }

        const participantsWithScores = await Promise.all(
          (participantsData || []).map(async (participant) => {
            const { data: scoreData, error: scoreError } = await $supabase
              .from('scores')
              .select('*')
              .eq('participant_id', participant.id)

            if (scoreError) {
              console.error('Error loading scores:', scoreError)
            }

            return { ...participant, scores: scoreData || [] }
          })
        )

      return { ...team, participants: participantsWithScores }
    })
  )

  teams.value = teamsWithParticipants
}

const createTeam = async () => {
  const { error } = await $supabase
    .from('teams')
    .insert([{
      ...newTeam.value,
      competition_id: competitionId
    }])

  if (error) {
    console.error('Error creating team:', error)
    return
  }

  newTeam.value = { name: '', location: '' }
  showTeamForm.value = false
  await loadTeams()
}

const deleteTeam = async (teamId: string) => {
  if (!confirm('Êtes-vous sûr de vouloir supprimer cette équipe ?')) {
    return
  }

  const { error } = await $supabase
    .from('teams')
    .delete()
    .eq('id', teamId)

  if (error) {
    console.error('Error deleting team:', error)
    return
  }

  await loadTeams()
}

const createParticipant = async (teamId: string) => {
  const { data: participantData, error: participantError } = await $supabase
    .from('participants')
    .insert([{
      ...newParticipant.value,
      team_id: teamId
    }])
    .select()
    .single()

  if (participantError) {
    console.error('Error creating participant:', participantError)
    return
  }

  newParticipant.value = { first_name: '', last_name: '', nickname: '' }
  showParticipantForm.value = null
  await loadTeams()
}

const deleteParticipant = async (participantId: string) => {
  if (!confirm('Êtes-vous sûr de vouloir supprimer ce participant ?')) {
    return
  }

  const { error } = await $supabase
    .from('participants')
    .delete()
    .eq('id', participantId)

  if (error) {
    console.error('Error deleting participant:', error)
    return
  }

  await loadTeams()
}

const getScoreValue = (scores: Score[], sessionId: string) => {
  const score = scores?.find(s => s.session_id === sessionId)
  return score ? score.score : 0
}

const updateScore = async (scoreId: string | undefined, participantId: string, sessionId: string, newScore: number) => {
  if (scoreId) {
    const { error } = await $supabase
      .from('scores')
      .update({ score: newScore })
      .eq('id', scoreId)

    if (error) {
      console.error('Error updating score:', error)
      return
    }
  } else {
    const { error } = await $supabase
      .from('scores')
      .insert([{
        participant_id: participantId,
        session_id: sessionId,
        score: newScore
      }])

    if (error) {
      console.error('Error creating score:', error)
      return
    }
  }

  await loadTeams()
}

const addSession = async () => {
  const nextSessionNumber = sessions.value.length > 0
    ? Math.max(...sessions.value.map(s => s.session_number)) + 1
    : 1
    
  const { error } = await $supabase
    .from('sessions')
    .insert([{
      competition_id: competitionId,
      name: `Session ${nextSessionNumber}`,
      session_number: nextSessionNumber
    }]);
    
  if (error) {
    console.error('Error adding session:', error);
    return;
  }
  
  await loadSessions();
}

onMounted(() => {
  loadCompetition()
  loadSessions()
  loadTeams()
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
      <h1 class="text-3xl font-bold text-gray-900">{{ competition.name }}</h1>
      <p class="mt-2 text-sm text-gray-600">
        {{ new Date(competition.date).toLocaleDateString('fr-FR') }} - Score max: {{ competition.max_score }}
      </p>
    </div>

    <div class="mb-6 flex space-x-4">
      <button
        @click="showTeamForm = !showTeamForm"
        class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
      >
        {{ showTeamForm ? 'Annuler' : 'Nouvelle Équipe' }}
      </button>

      <button
        @click="addSession"
        class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-colors"
      >
        + Ajouter une Session
      </button>

      <NuxtLink
        :to="`/competitions/${competitionId}/results`"
        class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
      >
        <svg class="h-4 w-4 mr-2 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        Voir le Dashboard
      </NuxtLink>
    </div>

    <div v-if="showTeamForm" class="bg-white shadow rounded-lg p-6 mb-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Créer une équipe</h2>
      <form @submit.prevent="createTeam" class="space-y-4">
        <div>
          <label for="team_name" class="block text-sm font-medium text-gray-700">
            Nom de l'équipe
          </label>
          <input
            v-model="newTeam.name"
            type="text"
            id="team_name"
            required
            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
        <div>
          <label for="location" class="block text-sm font-medium text-gray-700">
            Localisation
          </label>
          <input
            v-model="newTeam.location"
            type="text"
            id="location"
            required
            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
        <div class="flex justify-end">
          <button
            type="submit"
            class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Créer l'équipe
          </button>
        </div>
      </form>
    </div>

    <div v-if="teams.length === 0" class="text-center py-12">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">Aucune équipe</h3>
      <p class="mt-1 text-sm text-gray-500">
        Commencez par créer une équipe.
      </p>
    </div>

    <div v-else class="space-y-6">
      <div
        v-for="team in teams"
        :key="team.id"
        class="bg-white shadow rounded-lg overflow-hidden"
      >
        <div class="bg-gray-50 px-6 py-4 border-b border-gray-200">
          <div class="flex justify-between items-center">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">{{ team.name }}</h3>
              <p class="text-sm text-gray-600">{{ team.location }}</p>
            </div>
            <button
              @click="deleteTeam(team.id)"
              class="text-red-600 hover:text-red-800 transition-colors"
              title="Supprimer l'équipe"
            >
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>

        <div class="px-6 py-4">
          <div class="flex justify-between items-center mb-4">
            <h4 class="text-sm font-medium text-gray-900">Participants</h4>
            <div class="flex items-center space-x-3">
              <button
                @click="showParticipantForm = showParticipantForm === team.id ? null : team.id"
                class="text-sm text-blue-600 hover:text-blue-800 transition-colors"
              >
                {{ showParticipantForm === team.id ? 'Annuler' : '+ Ajouter un participant' }}
              </button>
            </div>
          </div>

          <div v-if="showParticipantForm === team.id" class="bg-gray-50 rounded-lg p-4 mb-4">
            <form @submit.prevent="createParticipant(team.id)" class="space-y-3">
              <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
                <div>
                  <label for="first_name" class="block text-xs font-medium text-gray-700">
                    Prénom
                  </label>
                  <input
                    v-model="newParticipant.first_name"
                    type="text"
                    id="first_name"
                    required
                    class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-1.5 px-3 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label for="last_name" class="block text-xs font-medium text-gray-700">
                    Nom
                  </label>
                  <input
                    v-model="newParticipant.last_name"
                    type="text"
                    id="last_name"
                    required
                    class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-1.5 px-3 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label for="nickname" class="block text-xs font-medium text-gray-700">
                    Surnom
                  </label>
                  <input
                    v-model="newParticipant.nickname"
                    type="text"
                    id="nickname"
                    required
                    class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-1.5 px-3 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </div>
              <div class="flex justify-end">
                <button
                  type="submit"
                  class="inline-flex items-center px-3 py-1.5 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  Ajouter
                </button>
              </div>
            </form>
          </div>

          <div v-if="team.participants.length === 0" class="text-center py-8 text-sm text-gray-500">
            Aucun participant dans cette équipe
          </div>

          <div v-else class="space-y-2">
            <div
              v-for="participant in team.participants"
              :key="participant.id"
              class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <div class="flex-1">
                <p class="text-sm font-medium text-gray-900">
                  {{ participant.first_name }} {{ participant.last_name }}
                  <span class="text-gray-500">({{ participant.nickname }})</span>
                </p>
              </div>
              <div class="flex items-center space-x-3">
                <div class="flex flex-wrap gap-2">
                  <div v-for="session in sessions" :key="session.id" class="flex items-center space-x-1">
                    <label class="text-xs text-gray-500 font-medium w-5 text-right" :title="session.name">S{{ session.session_number }}</label>
                    <input
                      :value="getScoreValue(participant.scores, session.id)"
                      @change="updateScore(participant.scores?.find(s => s.session_id === session.id)?.id, participant.id, session.id, Number(($event.target as HTMLInputElement).value))"
                      type="number"
                      min="0"
                      :max="competition?.max_score"
                      class="w-16 border border-gray-300 rounded-md shadow-sm py-1 px-1.5 text-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    />
                  </div>
                </div>
                <button
                  @click="deleteParticipant(participant.id)"
                  class="text-red-600 hover:text-red-800 transition-colors"
                  title="Supprimer"
                >
                  <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
