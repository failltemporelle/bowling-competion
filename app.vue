<template>
  <div class="min-h-screen bg-gray-50">
    <NuxtRouteAnnouncer />
    <nav class="bg-white shadow-md">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <NuxtLink to="/" class="text-2xl font-bold text-blue-600">
                Tournois Bowling
              </NuxtLink>
            </div>
            <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
              <NuxtLink
                to="/"
                class="inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors"
                activeClass="border-blue-500 text-gray-900"
                inactiveClass="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
              >
                Compétitions
              </NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </nav>
    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <NuxtPage />
    </main>
  </div>
</template>
