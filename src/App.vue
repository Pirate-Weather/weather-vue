<script setup>
import { ref } from 'vue'
import axios from 'axios'

const searchQuery = ref('')
const locations = ref([])
const selectedLocation = ref(null)
const weather = ref(null)
const loading = ref(false)

// 1. Search locations via Nominatim
const searchLocations = async () => {
  if (!searchQuery.value.trim()) return
  loading.value = true
  try {
    const response = await axios.get('https://nominatim.openstreetmap.org/search', {
      params: { q: searchQuery.value, format: 'json', limit: 5 },
      headers: { 'User-Agent': 'WeatherVueCleanApp/2.0' }
    })
    locations.value = response.data
  } catch (error) {
    console.error('Geocoding error:', error)
  } finally {
    loading.value = false
  }
}

// 2. Select location and fetch from Pirate Weather using the secure env key
const selectLocation = async (loc) => {
  selectedLocation.value = loc
  searchQuery.value = loc.display_name
  locations.value = []

  const apiKey = import.meta.env.VITE_PIRATE_WEATHER_API_KEY
  if (!apiKey) {
    console.error("Pirate Weather API key is missing in your .env file!")
    return
  }

    const useMock = true; // Toggle this to false when you're ready to use the real API

  try {
    // Pirate Weather endpoint format: /forecast/[key]/[lat],[lon]
    const url = useMock 
      ? '/mock-weather.json' 
      : `https://api.pirateweather.net/forecast/${apiKey}/${loc.lat},${loc.lon}`;

    const response = await axios.get(url, {
      params: useMock ? {} : { units: 'si' }
    });
    weather.value = response.data
  } catch (error) {
    console.error('Weather fetch error:', error)
  }
}

// Helper to convert UNIX timestamp to day name (e.g., "Monday")
const formatDay = (timestamp) => {
  return new Date(timestamp * 1000).toLocaleDateString('en-US', { weekday: 'short' })
}

// Simple helper to map Pirate Weather text codes to clean emojis
const getWeatherIcon = (iconString) => {
  const icons = {
    'clear-day': '☀️',
    'clear-night': '🌙',
    'rain': '🌧️',
    'snow': '❄️',
    'sleet': '🌨️',
    'wind': '💨',
    'fog': '🌫️',
    'cloudy': '☁️',
    'partly-cloudy-day': '⛅',
    'partly-cloudy-night': '☁️🌙'
  }
  return icons[iconString] || '🌡️'
}
</script>

<template>
  <main class="weather-container">
  <div class="relative grid min-h-screen grid-rows-[1fr_auto_1fr] bg-white [--pattern-fg:var(--color-gray-950)]/5 dark:bg-gray-950 dark:[--pattern-fg:var(--color-white)]/10">
  <div class="row-start-2 bg-gray-100 p-1 dark:bg-white/10 w-300 m-auto">
    <div class="rounded-xl bg-white p-10 text-gray-700 dark:bg-gray-950 dark:text-gray-300">
      <!-- Search Box -->
    <div class="flex gap-2 justify-between">
      <input 
        v-model="searchQuery" 
        @keyup.enter="searchLocations"
        placeholder="Search city or location..."
        class="p-3 rounded-sm outline outline-black/5 dark:-outline-offset-1 dark:outline-white/10"
      />
      <button @click="searchLocations" class="p-3 rounded-sm bg-orange-500 hover:bg-orange-700">Search</button>
    </div>

    <!-- Nominatim Results Dropdown -->
    <ul v-if="locations.length" class="absolute p-5 mt-2 rounded-sm outline outline-black/5 dark:-outline-offset-1 dark:outline-white/10 bg-white text-gray-700 dark:bg-gray-950 dark:text-gray-300">
      <li v-for="loc in locations" :key="loc.place_id" @click="selectLocation(loc)" class="p-2 hover:bg-orange-700">
        {{ loc.display_name }}
      </li>
    </ul>
    </div>
    <div class="rounded-xl bg-white p-10 text-gray-700 dark:bg-gray-950 dark:text-gray-300">
    <!-- Weather Display Panel -->
    <div v-if="weather" class="weather-dashboard">
      <h2 class="text-2xl">{{ selectedLocation?.display_name }}</h2>

      <!-- Current Conditions Card -->
      <div class="flex mt-2 mb-2">
        <div class="text-6xl">{{ getWeatherIcon(weather.currently.icon) }}</div>
        <div class="text-2xl">
          <span class="temp">{{ Math.round(weather.currently.temperature) }}°</span>
          <p class="summary">{{ weather.currently.summary }}</p>
        </div>
      </div>

      <!-- 7-Day Forecast Grid -->
      <h3 class="text-xl text-center mt-5 mb-5">7-Day Forecast</h3>
      <div class="grid gap-2">
        <div v-for="day in weather.daily.data" :key="day.time" class="flex justify-between p-3 rounded-sm outline outline-black/5 dark:-outline-offset-1 dark:outline-white/10 bg-white text-gray-700 dark:bg-gray-950 dark:text-gray-300">
          <span class="text-lg">{{ formatDay(day.time) }}</span>
          <span class="text-xl">{{ getWeatherIcon(day.icon) }}</span>
          <div class="text-lg flex gap-2">
            <span class="high">{{ Math.round(day.temperatureHigh) }}°</span>
            <span class="low">{{ Math.round(day.temperatureLow ?? day.temperatureMin) }}°</span>
          </div>
        </div>
      </div>
    </div>
    </div>
  </div>
</div>
  </main>
</template>