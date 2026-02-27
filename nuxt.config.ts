// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-04-03',
  devtools: { enabled: false },
  css: ['~/assets/css/main.css'],
  postcss: {
    plugins: {
      tailwindcss: {},
      autoprefixer: {},
    },
  },
  runtimeConfig: {
    public: {
      supabaseUrl: 'https://almrmxelkpgyhqxwfuol.supabase.co',
      supabaseAnonKey: 'sb_publishable_knYsB5CdSoPjxhN9Ag7jcw_L9FZrvOe'
      //supabaseUrl: process.env.VITE_SUPABASE_URL,
      //supabaseAnonKey: process.env.VITE_SUPABASE_ANON_KEY
    }
  }
})
