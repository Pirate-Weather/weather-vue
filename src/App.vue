<script setup>
import { ref, watch, computed } from 'vue'
import axios from 'axios'
import { 
  Search, 
  Sun,
  Moon, 
  CloudRain, 
  Snowflake, 
  Wind, 
  Cloud, 
  CloudFog, 
  CloudSun, 
  CloudMoon, 
  Compass, 
  Droplets, 
  Eye, 
  Activity, 
  AlertTriangle, 
  Thermometer,
  CloudLightning,
  CloudDrizzle,
  ChevronDown,
  ChevronUp
} from '@lucide/vue'

const searchQuery = ref('')
const locations = ref([])
const selectedLocation = ref(null)
const rawWeather = ref(null)
const loading = ref(false)

// User Preferences
const units = ref('si') // 'si' base for calculations (Celsius, m/s, km)
const alertExpanded = ref(false)

// Search locations via Nominatim with address details to format clean names
const searchLocations = async () => {
  if (!searchQuery.value.trim()) return
  loading.value = true
  try {
    const response = await axios.get('https://nominatim.openstreetmap.org/search', {
      params: { 
        q: searchQuery.value, 
        format: 'json', 
        limit: 5,
        addressdetails: 1 
      },
      headers: { 'User-Agent': 'WeatherVueCleanApp/2.0' }
    })
    locations.value = response.data
  } catch (error) {
    console.error('Geocoding error:', error)
  } finally {
    loading.value = false
  }
}

// Helper to format clean location name
const formatLocationName = (loc) => {
  const addr = loc.address || {}
  const city = addr.city || addr.town || addr.village || addr.municipality
  const state = addr.state || addr.province
  const country = addr.country
  return [city, state, country].filter(Boolean).join(', ')
}

// Check if minutely data contains actual precipitation and assign colors/heights
const hasPrecipitation = computed(() => {
  if (!rawWeather.value || !rawWeather.value.minutely || !rawWeather.value.minutely.data) return false
  return rawWeather.value.minutely.data.some(min => min.precipIntensity > 0)
})

const getPrecipColor = (min) => {
  const intensity = min.precipIntensity || 0
  const isSnow = min.precipType === 'snow'
  const thresholdFactor = isSnow ? 3 : 1 // Snow thresholds are roughly 1/3 of rain/general

  const adjustedIntensity = intensity * thresholdFactor

  if (adjustedIntensity >= 10) return 'bg-red-600' // Heavy
  if (adjustedIntensity >= 2.5) return 'bg-yellow-400'  // Medium
  if (adjustedIntensity >= 0.4) return 'bg-green-400'  // Light
  if (adjustedIntensity > 0) return 'bg-green-200'     // Very light
  return 'bg-transparent'
}

// Select location and fetch weather (only once)
const selectLocation = async (loc) => {
  selectedLocation.value = loc
  searchQuery.value = formatLocationName(loc)
  locations.value = []

  const apiKey = import.meta.env.VITE_PIRATE_WEATHER_API_KEY
  if (!apiKey) {
    console.error("Pirate Weather API key is missing in your .env file!")
    return
  }

  const useMock = false // Set to true to use mock-weather.json
  loading.value = true

  try {
    const url = useMock 
      ? '/mock-weather.json' 
      : `https://api.pirateweather.net/forecast/${apiKey}/${loc.lat},${loc.lon}?units=si&version=2&include=airqualitydetails&aqiunits=us`

    const response = await axios.get(url)
    rawWeather.value = response.data
  } catch (error) {
    console.error('Weather fetch error:', error)
  } finally {
    loading.value = false
  }
}

// Client-side unit converters
const formatTemp = (tempC) => {
  if (tempC === undefined || tempC === null) return '--'
  if (units.value === 'us') {
    return Math.round((tempC * 9/5) + 32)
  }
  return Math.round(tempC)
}

const formatWindSpeed = (speedMs) => {
  if (speedMs === undefined || speedMs === null) return '--'
  if (units.value === 'us') {
    return Math.round(speedMs * 2.23694) // m/s to mph
  }
  return Math.round(speedMs * 3.6) // m/s to km/h
}

const formatVisibility = (visKm) => {
  if (visKm === undefined || visKm === null) return 'N/A'
  if (units.value === 'us') {
    return Math.round(visKm * 0.621371) // km to miles
  }
  return Math.round(visKm)
}

// Computed weather object transformed based on selected units
const weather = computed(() => {
  if (!rawWeather.value) return null
  return rawWeather.value
})

const formatDay = (timestamp) => {
  return new Date(timestamp * 1000).toLocaleDateString('en-US', { weekday: 'short' })
}

const formatDate = (timestamp) => {
  return new Date(timestamp * 1000).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

const formatHour = (timestamp) => {
  return new Date(timestamp * 1000).toLocaleTimeString('en-US', { hour: 'numeric', hour12: true })
}

const getWindDirection = (bearing) => {
  if (bearing === undefined || bearing === null) return ''
  const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']
  const index = Math.round((bearing % 360) / 22.5)
  return directions[index % 16]
}

const getWeatherIconComponent = (iconString) => {
  switch (iconString) {
    case 'clear-day': return Sun
    case 'clear-night': return Moon
    case 'rain': return CloudRain
    case 'snow': return Snowflake
    case 'sleet': return CloudDrizzle
    case 'wind': return Wind
    case 'fog': return CloudFog
    case 'cloudy': return Cloud
    case 'partly-cloudy-day': return CloudSun
    case 'partly-cloudy-night': return CloudMoon
    case 'thunderstorm': return CloudLightning
    default: return Sun
  }
}
</script>

<template>
  <div class="min-h-screen">
    <main class="min-h-screen bg-slate-100 text-slate-800 p-4 sm:p-6 md:p-8 flex flex-col items-center">
      <div class="w-full max-w-4xl space-y-6">
        
        <!-- Header Controls: Search & Unit Toggle -->
        <div class="flex flex-col sm:flex-row gap-3 items-center justify-between bg-white p-4 rounded-2xl shadow-sm border border-slate-200">
          
          <!-- Search Box -->
          <div class="relative w-full sm:w-96">
            <div class="flex items-center gap-2 bg-slate-50 px-3 py-2 rounded-xl border border-slate-200">
              <Search class="w-5 h-5 text-slate-400 shrink-0" />
              <input 
                v-model="searchQuery" 
                @keyup.enter="searchLocations"
                placeholder="Search city or location..."
                class="w-full bg-transparent outline-none text-sm placeholder:text-slate-400 text-slate-800"
              />
              <button 
                @click="searchLocations" 
                class="px-3 py-1.5 bg-orange-500 hover:bg-orange-600 text-white rounded-lg text-sm font-medium transition shrink-0"
              >
                Search
              </button>
            </div>

            <!-- Dropdown -->
            <ul v-if="locations.length" class="absolute z-50 left-0 right-0 mt-2 bg-white border border-slate-200 rounded-xl shadow-lg overflow-hidden">
              <li 
                v-for="loc in locations" 
                :key="loc.place_id" 
                @click="selectLocation(loc)" 
                class="px-4 py-3 text-sm hover:bg-orange-50 cursor-pointer transition border-b border-slate-100 last:border-none"
              >
                {{ formatLocationName(loc) }}
              </li>
            </ul>
          </div>

          <!-- Unit Toggle Only -->
          <div class="flex items-center gap-3 w-full sm:w-auto justify-end">
            <button 
              @click="units = units === 'si' ? 'us' : 'si'"
              class="px-3 py-2 bg-slate-100 hover:bg-slate-200 rounded-xl text-xs font-semibold transition flex items-center gap-1.5"
            >
              <Thermometer class="w-4 h-4 text-orange-500" />
              <span>{{ units === 'si' ? 'Metric (°C)' : 'Imperial (°F)' }}</span>
            </button>
          </div>
        </div>

        <!-- Weather Panel -->
        <div v-if="weather" class="space-y-6">
          
          <!-- Alerts Banner -->
          <div v-if="weather.alerts && weather.alerts.length" class="bg-red-50 border border-red-200 rounded-2xl p-4 transition-all">
            <div @click="alertExpanded = !alertExpanded" class="flex items-start justify-between cursor-pointer gap-3">
              <div class="flex items-start gap-3">
                <AlertTriangle class="w-6 h-6 text-red-500 shrink-0 mt-0.5" />
                <div>
                  <h4 class="font-semibold text-red-800 text-sm flex items-center gap-2">
                    {{ weather.alerts[0].title }}
                    <span class="text-xs font-normal underline opacity-80">(Click to {{ alertExpanded ? 'collapse' : 'expand' }})</span>
                  </h4>
                  <p v-if="!alertExpanded" class="text-xs text-red-700 mt-1 line-clamp-1">{{ weather.alerts[0].description }}</p>
                </div>
              </div>
              <component :is="alertExpanded ? ChevronUp : ChevronDown" class="w-5 h-5 text-red-500 shrink-0" />
            </div>
            <div v-if="alertExpanded" class="mt-3 pt-3 border-t border-red-200 text-xs text-red-700 space-y-2 whitespace-pre-line leading-relaxed">
              {{ weather.alerts[0].description }}
            </div>
          </div>

          <!-- Current Conditions Card -->
          <div class="bg-white p-6 sm:p-8 rounded-3xl shadow-sm border border-slate-200">
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
              
              <div class="space-y-2">
                <div class="flex items-center gap-2 text-slate-500 text-sm font-medium">
                  <Compass class="w-4 h-4 text-orange-500" />
                  <span>{{ selectedLocation ? formatLocationName(selectedLocation) : '' }}</span>
                </div>
                <div class="flex items-center gap-6">
                  <component :is="getWeatherIconComponent(weather.currently.icon)" class="w-20 h-20 sm:w-24 sm:h-24 text-orange-500 shrink-0" />
                  <div>
                    <span class="text-6xl sm:text-7xl font-bold tracking-tight">
                      {{ formatTemp(weather.currently.temperature) }}°
                    </span>
                    <div class="space-y-1 mt-1">
                      <span class="text-lg font-medium block">{{ weather.currently.summary }}</span>
                      <p class="text-xs text-slate-500">
                        Feels like {{ formatTemp(weather.currently.apparentTemperature ?? weather.currently.temperature) }}°
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Metrics Grid (Fixed Sizing) -->
              <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 w-full md:w-auto">
                <div class="h-24 bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between">
                  <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                    <Droplets class="w-3.5 h-3.5 text-blue-500" />
                    <span>Humidity</span>
                  </div>
                  <span class="text-base font-semibold">{{ Math.round(weather.currently.humidity * 100) }}%</span>
                </div>

                <div class="h-24 bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between">
                  <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                    <Wind class="w-3.5 h-3.5 text-teal-500" />
                    <span>Wind</span>
                  </div>
                  <div>
                    <div class="text-base font-semibold">
                      {{ formatWindSpeed(weather.currently.windSpeed) }} <span class="text-xs font-normal">{{ units === 'si' ? 'km/h' : 'mph' }}</span> {{ getWindDirection(weather.currently.windBearing) }}
                    </div>
                    <div v-if="weather.currently.windGust" class="text-[10px] text-slate-400 mt-0.5">
                      Gusts: {{ formatWindSpeed(weather.currently.windGust) }}
                    </div>
                  </div>
                </div>

                <div class="h-24 bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between">
                  <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                    <Eye class="w-3.5 h-3.5 text-purple-500" />
                    <span>Visibility</span>
                  </div>
                  <span class="text-base font-semibold">{{ formatVisibility(weather.currently.visibility) }} <span class="text-xs font-normal">{{ units === 'si' ? 'km' : 'mi' }}</span></span>
                </div>

                <div class="h-24 bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between">
                  <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                    <Activity class="w-3.5 h-3.5 text-amber-500" />
                    <span>AQI</span>
                  </div>
                  <span class="text-base font-semibold">{{ weather.currently.airQualityIndex ?? 'N/A' }}</span>
                </div>
              </div>

            </div>
          </div>

         <!-- Minutely Precipitation Forecast (Unified Timeline) -->
          <div v-if="hasPrecipitation" class="bg-blue-50/50 border border-blue-200 rounded-3xl p-6 shadow-sm">
            <div class="flex items-center gap-2 text-blue-800 text-sm font-semibold mb-3">
              <CloudRain class="w-5 h-5 text-blue-500" />
              <span>{{ weather.minutely.summary }}</span>
            </div>
            
            <!-- Unified container box for all bars -->
            <div class="bg-white/80 border border-blue-100 rounded-2xl p-4">
              <div class="flex items-end gap-1 overflow-x-auto pb-2 h-20 scrollbar-thin">
                <div 
                  v-for="min in weather.minutely.data.filter((_, i) => i % 2 === 0)" 
                  :key="min.time" 
                  class="flex-1 flex flex-col items-center justify-end gap-1 min-w-[12px] h-full group relative"
                  :title="`${formatHour(min.time)}: ${Math.round(min.precipProbability * 100)}% chance (${min.precipIntensity} mm/h)`"
                >
                  <!-- Bar height scales with intensity -->
                  <div 
                    class="w-full rounded-t transition-all" 
                    :class="getPrecipColor(min)"
                    :style="{ height: `${Math.max(8, Math.min(100, (min.precipIntensity / 10) * 100))}%` }"
                  ></div>
                </div>
              </div>
              <!-- Timeline labels below -->
              <div class="flex justify-between text-[10px] text-slate-400 mt-2 pt-2 border-t border-slate-100">
                <span>Now</span>
                <span>+30 min</span>
                <span>+60 min</span>
              </div>
            </div>
          </div>

          <!-- Hourly Forecast Horizontal Scroll -->
          <div class="bg-white p-6 rounded-3xl shadow-sm border border-slate-200">
            <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-4">Hourly Forecast</h3>
            <div class="flex gap-3 overflow-x-auto pb-2 scrollbar-thin">
              <div 
                v-for="hour in weather.hourly.data.slice(0, 24)" 
                :key="hour.time" 
                class="flex flex-col items-center justify-between p-3 min-w-[76px] bg-slate-50 rounded-2xl border border-slate-100 shrink-0"
              >
                <span class="text-xs text-slate-500">{{ formatHour(hour.time) }}</span>
                <component :is="getWeatherIconComponent(hour.icon)" class="w-6 h-6 text-orange-500 my-2" />
                <span class="text-sm font-bold">{{ formatTemp(hour.temperature) }}°</span>
              </div>
            </div>
          </div>

          <!-- 7-Day Forecast Grid -->
          <div class="bg-white p-6 rounded-3xl shadow-sm border border-slate-200">
            <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-4">7-Day Forecast</h3>
            <div class="space-y-3">
              <div 
                v-for="day in weather.daily.data" 
                :key="day.time" 
                class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-100"
              >
                <div class="w-32">
                  <span class="font-medium text-slate-700 block">{{ formatDay(day.time) }}</span>
                  <span class="text-xs text-slate-400">{{ formatDate(day.time) }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <component :is="getWeatherIconComponent(day.icon)" class="w-5 h-5 text-orange-500" />
                  <span class="text-xs text-slate-500 hidden sm:inline">{{ day.summary }}</span>
                </div>
                <div class="flex items-center gap-3 text-sm">
                  <span class="font-bold">{{ formatTemp(day.temperatureHigh) }}°</span>
                  <span class="text-slate-400">{{ formatTemp(day.temperatureLow ?? day.temperatureMin) }}°</span>
                </div>
              </div>
            </div>
          </div>

        </div>

      </div>
    </main>
  </div>
</template>