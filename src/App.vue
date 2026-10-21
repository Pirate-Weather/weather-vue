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
const expandedAlerts = ref({})
const expandedDays = ref({})

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

  const useMock = false
  loading.value = true

  try {
    const url = useMock 
      ? '/mock-weather.json' 
      : `https://api.pirateweather.net/forecast/${apiKey}/${loc.lat},${loc.lon}?units=si&version=2&include=airqualitydetails,day_night_forecast&aqiunits=us`

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

const getDayPart = (index, isNight = false) => {
  if (rawWeather.value?.day_night?.data) {
    const idx = index * 2 + (isNight ? 1 : 0)
    return rawWeather.value.day_night.data[idx]
  }
  return null
}
</script>

<template>
  <div class="min-h-screen">
    <main class="min-h-screen bg-slate-100 text-slate-800 p-4 sm:p-6 md:p-8 flex flex-col items-center">
      <div class="w-full max-w-4xl space-y-6">
        
        <!-- Header Controls: Search & Unit Toggle -->
        <div class="flex flex-col sm:flex-row gap-3 items-center justify-between bg-white p-4 rounded-2xl shadow-sm border border-slate-200">
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
          
          <!-- Multiple Alerts Banners -->
          <div v-if="weather.alerts && weather.alerts.length" class="space-y-3">
            <div 
              v-for="(alert, index) in weather.alerts" 
              :key="index"
              class="border rounded-2xl p-4 transition-all"
              :class="alert.severity === 'severe' || alert.severity === 'warning' ? 'bg-red-50 border-red-200' : 'bg-amber-50 border-amber-200'"
            >
              <div @click="expandedAlerts[index] = !expandedAlerts[index]" class="flex items-start justify-between cursor-pointer gap-3">
                <div class="flex items-start gap-3">
                  <AlertTriangle class="w-6 h-6 shrink-0 mt-0.5" :class="alert.severity === 'severe' ? 'text-red-600' : 'text-amber-500'" />
                  <div>
                    <h4 class="font-semibold text-sm flex items-center gap-2" :class="alert.severity === 'severe' ? 'text-red-900' : 'text-amber-900'">
                      {{ alert.title }}
                      <span class="text-xs font-normal underline opacity-80">(Click to {{ expandedAlerts[index] ? 'collapse' : 'expand' }})</span>
                    </h4>
                    <p v-if="!expandedAlerts[index]" class="text-xs mt-1 line-clamp-1" :class="alert.severity === 'severe' ? 'text-red-700' : 'text-amber-700'">{{ alert.description }}</p>
                  </div>
                </div>
                <component :is="expandedAlerts[index] ? ChevronUp : ChevronDown" class="w-5 h-5 shrink-0" :class="alert.severity === 'severe' ? 'text-red-600' : 'text-amber-500'" />
              </div>
              <div v-if="expandedAlerts[index]" class="mt-3 pt-3 border-t text-xs space-y-2 whitespace-pre-line leading-relaxed" :class="alert.severity === 'severe' ? 'border-red-200 text-red-700' : 'border-amber-200 text-amber-700'">
                {{ alert.description }}
              </div>
            </div>
          </div>

          <!-- Current Conditions Card -->
          <div class="bg-white p-6 sm:p-8 rounded-3xl shadow-sm border border-slate-200 space-y-6">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-6">
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
            </div>

            <!-- 6 Metrics Items Grid Below -->
            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-3 pt-4 border-t border-slate-100">
              <div class="bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between h-20">
                <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                  <Wind class="w-3.5 h-3.5 text-teal-500" />
                  <span>Wind</span>
                </div>
                <span class="text-sm font-semibold">
                  {{ formatWindSpeed(weather.currently.windSpeed) }} <span class="text-[10px] font-normal">{{ units === 'si' ? 'km/h' : 'mph' }}</span>
                </span>
              </div>

              <div class="bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between h-20">
                <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                  <Activity class="w-3.5 h-3.5 text-amber-500" />
                  <span>AQI</span>
                </div>
                <span class="text-sm font-semibold">{{ weather.currently.airQualityIndex ?? 'N/A' }}</span>
              </div>

              <div class="bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between h-20">
                <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                  <Compass class="w-3.5 h-3.5 text-orange-500" />
                  <span>Pressure</span>
                </div>
                <span class="text-sm font-semibold">{{ weather.currently.pressure ? Math.round(weather.currently.pressure) : 'N/A' }} <span class="text-[10px] font-normal">hPa</span></span>
              </div>

              <div class="bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between h-20">
                <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                  <Thermometer class="w-3.5 h-3.5 text-red-500" />
                  <span>Dew Point</span>
                </div>
                <span class="text-sm font-semibold">{{ formatTemp(weather.currently.dewPoint) }}°</span>
              </div>

              <div class="bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between h-20">
                <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                  <Droplets class="w-3.5 h-3.5 text-blue-500" />
                  <span>Humidity</span>
                </div>
                <span class="text-sm font-semibold">{{ Math.round(weather.currently.humidity * 100) }}%</span>
              </div>

              <div class="bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-col justify-between h-20">
                <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                  <Eye class="w-3.5 h-3.5 text-purple-500" />
                  <span>Visibility</span>
                </div>
                <span class="text-sm font-semibold">{{ formatVisibility(weather.currently.visibility) }} <span class="text-[10px] font-normal">{{ units === 'si' ? 'km' : 'mi' }}</span></span>
              </div>
            </div>
          </div>

          <!-- Minutely Precipitation Forecast (Unified Timeline) -->
          <div v-if="hasPrecipitation" class="bg-blue-50/50 border border-blue-200 rounded-3xl p-6 shadow-sm">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center gap-2 text-blue-800 text-sm font-semibold">
                <CloudRain class="w-5 h-5 text-blue-500" />
                <span>{{ weather.minutely.summary }}</span>
              </div>
              <div class="text-xs text-blue-700 font-medium">
                Dew Point: {{ formatTemp(weather.minutely.data[0]?.dewPoint) }}°
              </div>
            </div>
            
            <div class="bg-white/80 border border-blue-100 rounded-2xl p-4">
              <div class="flex items-end gap-1 overflow-x-auto pb-2 h-20 scrollbar-thin">
                <div 
                  v-for="min in weather.minutely.data.filter((_, i) => i % 2 === 0)" 
                  :key="min.time" 
                  class="flex-1 flex flex-col items-center justify-end gap-1 min-w-[12px] h-full group relative"
                  :title="`${formatHour(min.time)}: ${Math.round(min.precipProbability * 100)}% chance, Intensity: ${min.precipIntensity} mm/h, Dew Point: ${formatTemp(min.dewPoint)}°`"
                >
                  <div 
                    class="w-full rounded-t transition-all" 
                    :class="getPrecipColor(min)"
                    :style="{ height: `${Math.max(8, Math.min(100, (min.precipIntensity / 10) * 100))}%` }"
                  ></div>
                </div>
              </div>
              <div class="flex justify-between text-[10px] text-slate-400 mt-2 pt-2 border-t border-slate-100">
                <span>Now</span>
                <span>+30 min</span>
                <span>+60 min</span>
              </div>

              <!-- Minutely Legend Underneath -->
              <div class="flex flex-wrap items-center justify-center gap-4 mt-3 pt-3 border-t border-blue-100/60 text-[11px] text-slate-600">
                <span class="font-semibold text-slate-700">Legend:</span>
                <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded bg-green-200 inline-block"><span>Very Light</span></span></div>
                <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded bg-green-400 inline-block"><span>Light</span></span></div>
                <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded bg-yellow-400 inline-block"><span>Medium</span></span></div>
                <div class="flex items-center gap-1.5"><span class="w-3 h-3 rounded bg-red-600 inline-block"><span>Heavy</span></span></div>
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

          <!-- 7-Day Forecast Grid (Expandable Day/Night) -->
          <div class="bg-white p-6 rounded-3xl shadow-sm border border-slate-200">
            <h3 class="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-4">7-Day Forecast</h3>
            <div class="space-y-3">
              <div 
                v-for="(day, index) in weather.daily.data" 
                :key="day.time"
                class="bg-slate-50 rounded-2xl border border-slate-100 overflow-hidden transition"
              >
                <!-- Summary Row (Clickable to Expand) -->
                <div 
                  @click="expandedDays[index] = !expandedDays[index]"
                  class="flex items-center justify-between p-4 cursor-pointer hover:bg-slate-100/60 transition"
                >
                  <div class="w-32">
                    <span class="font-medium text-slate-700 block">{{ formatDay(day.time) }}</span>
                    <span class="text-xs text-slate-400">{{ formatDate(day.time) }}</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <component :is="getWeatherIconComponent(day.icon)" class="w-5 h-5 text-orange-500" />
                    <span class="text-xs text-slate-500 hidden sm:inline truncate max-w-xs">{{ day.summary }}</span>
                  </div>
                  <div class="flex items-center gap-4 text-sm">
                    <div class="flex items-center gap-2">
                      <span class="font-bold">{{ formatTemp(day.temperatureHigh) }}°</span>
                      <span class="text-slate-400">{{ formatTemp(day.temperatureLow ?? day.temperatureMin) }}°</span>
                    </div>
                    <component :is="expandedDays[index] ? ChevronUp : ChevronDown" class="w-4 h-4 text-slate-400" />
                  </div>
                </div>

                <!-- Expanded Day / Night Details Section -->
                <div v-if="expandedDays[index]" class="px-4 pb-4 pt-1 border-t border-slate-200/60 bg-white/50 grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                  <!-- Day Breakdown -->
                  <div class="p-3 bg-orange-50/50 border border-orange-100 rounded-xl space-y-2">
                    <div class="flex items-center justify-between">
                      <div class="font-semibold text-orange-900 flex items-center gap-1.5">
                        <component :is="getWeatherIconComponent(getDayPart(index, false)?.icon)" class="w-4 h-4 text-orange-500" />
                        <span>Day Forecast</span>
                      </div>
                      <span class="text-sm font-bold text-orange-900">{{ formatTemp(getDayPart(index, false)?.temperature ?? day.temperatureHigh) }}°</span>
                    </div>
                    <p class="text-slate-600 leading-relaxed">{{ getDayPart(index, false)?.summary || day.summary }}</p>
                    <div class="flex justify-between pt-1 border-t border-orange-100 text-[11px] text-slate-500">
                      <span>Wind: <strong>{{ formatWindSpeed(getDayPart(index, false)?.windSpeed ?? day.windSpeed) }} {{ units === 'si' ? 'km/h' : 'mph' }}</strong></span>
                      <span>UV: <strong>{{ getDayPart(index, false)?.uvIndex ?? day.uvIndex ?? 'N/A' }}</strong></span>
                    </div>
                  </div>

                  <!-- Night Breakdown -->
                  <div class="p-3 bg-indigo-50/50 border border-indigo-100 rounded-xl space-y-2">
                    <div class="flex items-center justify-between">
                      <div class="font-semibold text-indigo-900 flex items-center gap-1.5">
                        <component :is="getWeatherIconComponent(getDayPart(index, true)?.icon)" class="w-4 h-4 text-indigo-500" />
                        <span>Night Forecast</span>
                      </div>
                      <span class="text-sm font-bold text-indigo-900">{{ formatTemp(getDayPart(index, true)?.temperature ?? day.temperatureLow ?? day.temperatureMin) }}°</span>
                    </div>
                    <p class="text-slate-600 leading-relaxed">{{ getDayPart(index, true)?.summary || day.summary }}</p>
                    <div class="flex justify-between pt-1 border-t border-indigo-100 text-[11px] text-slate-500">
                      <span>Humidity: <strong>{{ Math.round((getDayPart(index, true)?.humidity ?? day.humidity ?? 0) * 100) }}%</strong></span>
                      <span>Dew Point: <strong>{{ formatTemp(getDayPart(index, true)?.dewPoint ?? day.dewPoint) }}°</strong></span>
                    </div>
                  </div>
                </div>

              </div>
            </div>
          </div>

        </div>

      </div>
    </main>
  </div>
</template>