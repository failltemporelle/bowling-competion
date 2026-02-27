<script setup lang="ts">
import type { Competition } from '~/types/database'

const { $supabase } = useNuxtApp()
const competitions = ref<Competition[]>([])
const showForm = ref(false)
const newCompetition = ref({
  name: '',
  date: '',
  max_score: 300
})

const loadCompetitions = async () => {
  const { data, error } = await $supabase
    .from('competitions')
    .select('*')
    .order('date', { ascending: false })

  if (error) {
    console.error('Error loading competitions:', error)
    return
  }

  competitions.value = data || []
}

const createCompetition = async () => {
  const { error } = await $supabase
    .from('competitions')
    .insert([newCompetition.value])

  if (error) {
    console.error('Error creating competition:', error)
    return
  }

  newCompetition.value = { name: '', date: '', max_score: 300 }
  showForm.value = false
  await loadCompetitions()
}

const deleteCompetition = async (id: string) => {
  if (!confirm('Êtes-vous sûr de vouloir supprimer cette compétition ?')) {
    return
  }

  const { error } = await $supabase
    .from('competitions')
    .delete()
    .eq('id', id)

  if (error) {
    console.error('Error deleting competition:', error)
    return
  }

  await loadCompetitions()
}

onMounted(() => {
  loadCompetitions()
})
</script>

<template>
  <div class="px-4 sm:px-0">
    <div class="sm:flex sm:items-center sm:justify-between mb-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Compétitions de Bowling</h1>
        <p class="mt-2 text-sm text-gray-700">
          Gérez vos tournois et suivez les scores
        </p>
      </div>
      <div class="mt-4 sm:mt-0">
        <button
          @click="showForm = !showForm"
          class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
        >
          {{ showForm ? 'Annuler' : 'Nouvelle Compétition' }}
        </button>
      </div>
    </div>

    <div v-if="showForm" class="bg-white shadow rounded-lg p-6 mb-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Créer une compétition</h2>
      <form @submit.prevent="createCompetition" class="space-y-4">
        <div>
          <label for="name" class="block text-sm font-medium text-gray-700">
            Nom de la compétition
          </label>
          <input
            v-model="newCompetition.name"
            type="text"
            id="name"
            required
            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
        <div>
          <label for="date" class="block text-sm font-medium text-gray-700">
            Date
          </label>
          <input
            v-model="newCompetition.date"
            type="date"
            id="date"
            required
            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
        <div>
          <label for="max_score" class="block text-sm font-medium text-gray-700">
            Score maximum
          </label>
          <input
            v-model.number="newCompetition.max_score"
            type="number"
            id="max_score"
            required
            min="1"
            class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
        </div>
        <div class="flex justify-end">
          <button
            type="submit"
            class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Créer
          </button>
        </div>
      </form>
    </div>

    <div v-if="competitions.length === 0" class="text-center py-12">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">Aucune compétition</h3>
      <p class="mt-1 text-sm text-gray-500">
        Commencez par créer une nouvelle compétition.
      </p>
    </div>

    <div v-else class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      <div
        v-for="competition in competitions"
        :key="competition.id"
        class="bg-white shadow rounded-lg p-6 hover:shadow-lg transition-shadow"
      >
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-lg font-semibold text-gray-900">
            {{ competition.name }}
          </h3>
          <button
            @click="deleteCompetition(competition.id)"
            class="text-red-600 hover:text-red-800 transition-colors"
            title="Supprimer"
          >
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
        </div>
        <div class="space-y-2 mb-4">
          <p class="text-sm text-gray-600">
            <span class="font-medium">Date :</span>
            {{ new Date(competition.date).toLocaleDateString('fr-FR') }}
          </p>
          <p class="text-sm text-gray-600">
            <span class="font-medium">Score max :</span>
            {{ competition.max_score }}
          </p>
        </div>
        <div class="flex space-x-2">
          <NuxtLink
            :to="`/competitions/${competition.id}`"
            class="flex-1 text-center px-4 py-2 border border-blue-600 rounded-md text-sm font-medium text-blue-600 hover:bg-blue-50 transition-colors"
          >
            Gérer
          </NuxtLink>
          <NuxtLink
            :to="`/competitions/${competition.id}/results`"
            class="flex-1 text-center px-4 py-2 bg-blue-600 rounded-md text-sm font-medium text-white hover:bg-blue-700 transition-colors"
          >
            Résultats
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>
