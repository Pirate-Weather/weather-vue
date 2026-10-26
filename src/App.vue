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

// Theme: saved choice wins, otherwise follow the system preference
const getInitialDark = () => {
  try {
    const saved = localStorage.getItem('theme')
    if (saved) return saved === 'dark'
  } catch {}
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}
const isDark = ref(getInitialDark())
watch(isDark, (dark) => document.documentElement.classList.toggle('dark', dark), { immediate: true })

const toggleDark = () => {
  isDark.value = !isDark.value
  try {
    localStorage.setItem('theme', isDark.value ? 'dark' : 'light')
  } catch {}
}

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

// Accumulations come back in cm (SI); show rain in mm and snow in cm
const formatPrecipAmount = (amountCm, type) => {
  if (!amountCm) return null
  if (units.value === 'us') {
    const inches = amountCm / 2.54
    return `${inches < 0.1 ? inches.toFixed(2) : inches.toFixed(1)} in`
  }
  if (type === 'snow') return `${amountCm.toFixed(1)} cm`
  const mm = amountCm * 10
  return `${mm < 1 ? mm.toFixed(1) : Math.round(mm)} mm`
}

// AQI is -999 when there is no data
const formatAqi = (aqi) => (aqi === undefined || aqi === null || aqi < 0) ? null : Math.round(aqi)

// US EPA AQI categories
const getAqiStyle = (aqi) => {
  if (aqi <= 50) return { label: 'Good', classes: 'bg-green-100 text-green-800 dark:bg-green-500/15 dark:text-green-300' }
  if (aqi <= 100) return { label: 'Moderate', classes: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-500/15 dark:text-yellow-300' }
  if (aqi <= 150) return { label: 'Unhealthy for Sensitive Groups', classes: 'bg-orange-100 text-orange-800 dark:bg-orange-500/15 dark:text-orange-300' }
  if (aqi <= 200) return { label: 'Unhealthy', classes: 'bg-red-100 text-red-800 dark:bg-red-500/15 dark:text-red-300' }
  if (aqi <= 300) return { label: 'Very Unhealthy', classes: 'bg-purple-100 text-purple-800 dark:bg-purple-500/15 dark:text-purple-300' }
  return { label: 'Hazardous', classes: 'bg-rose-200 text-rose-950 dark:bg-rose-900/40 dark:text-rose-200' }
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

// Normalized day/night parts so both halves always show the same fields
const getDayParts = (index, day) => [false, true].map(isNight => {
  const part = getDayPart(index, isNight) || {}
  return {
    isNight,
    label: isNight ? 'Night' : 'Day',
    icon: part.icon ?? day.icon,
    temperature: part.temperature ?? (isNight ? day.temperatureLow ?? day.temperatureMin : day.temperatureHigh),
    summary: part.summary || day.summary,
    precipProbability: part.precipProbability ?? day.precipProbability,
    precipAmount: formatPrecipAmount(part.precipAccumulation ?? day.precipAccumulation, part.precipType ?? day.precipType),
    windSpeed: part.windSpeed ?? day.windSpeed,
    windBearing: part.windBearing ?? day.windBearing,
    humidity: part.humidity ?? day.humidity,
    dewPoint: part.dewPoint ?? day.dewPoint,
    uvIndex: isNight ? null : (part.uvIndex ?? day.uvIndex),
    visibility: part.visibility ?? day.visibility
  }
})

// Full class strings so Tailwind can detect them
const dayPartStyles = {
  day: {
    card: 'bg-orange-50/50 border-orange-100 dark:bg-orange-500/10 dark:border-orange-500/20',
    label: 'text-orange-700 dark:text-orange-300',
    icon: 'text-orange-500 dark:text-orange-400',
    divider: 'border-orange-100 dark:border-orange-500/20'
  },
  night: {
    card: 'bg-indigo-50/50 border-indigo-100 dark:bg-indigo-500/10 dark:border-indigo-500/20',
    label: 'text-indigo-700 dark:text-indigo-300',
    icon: 'text-indigo-500 dark:text-indigo-400',
    divider: 'border-indigo-100 dark:border-indigo-500/20'
  }
}

// Metric tiles shown beside the current conditions
const currentMetrics = computed(() => {
  if (!weather.value) return []
  const c = weather.value.currently
  return [
    { label: 'Wind', icon: Wind, color: 'text-teal-500', value: `${getWindDirection(c.windBearing)} ${formatWindSpeed(c.windSpeed)}`.trim(), unit: units.value === 'si' ? 'km/h' : 'mph' },
    { label: 'AQI', icon: Activity, color: 'text-amber-500', value: formatAqi(c.airQualityIndex) ?? 'N/A' },
    { label: 'Pressure', icon: Compass, color: 'text-orange-500', value: c.pressure ? Math.round(c.pressure) : 'N/A', unit: 'hPa' },
    { label: 'Dew Point', icon: Thermometer, color: 'text-red-500', value: `${formatTemp(c.dewPoint)}°` },
    { label: 'Humidity', icon: Droplets, color: 'text-blue-500', value: `${Math.round(c.humidity * 100)}%` },
    { label: 'Visibility', icon: Eye, color: 'text-purple-500', value: formatVisibility(c.visibility), unit: units.value === 'si' ? 'km' : 'mi' }
  ]
})
</script>

<template>
  <div class="min-h-screen">
    <main class="min-h-screen bg-slate-100 text-slate-800 dark:bg-slate-950 dark:text-slate-100 p-4 sm:p-6 md:p-8 flex flex-col items-center transition-colors">
      <div class="w-full max-w-4xl space-y-6">

        <!-- Header Controls: Search, Unit & Theme Toggles -->
        <div class="flex flex-col sm:flex-row gap-3 items-center justify-between bg-white dark:bg-slate-900 p-4 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-800">
          <div class="relative w-full sm:w-96">
            <div class="flex items-center gap-2 bg-slate-50 dark:bg-slate-800 px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-700">
              <Search class="w-5 h-5 text-slate-400 shrink-0" />
              <input
                v-model="searchQuery"
                @keyup.enter="searchLocations"
                placeholder="Search city or location..."
                class="w-full bg-transparent outline-none text-sm placeholder:text-slate-400 text-slate-800 dark:text-slate-100"
              />
              <button
                @click="searchLocations"
                class="px-3 py-1.5 bg-orange-500 hover:bg-orange-600 text-white rounded-lg text-sm font-medium transition shrink-0"
              >
                Search
              </button>
            </div>
            <ul v-if="locations.length" class="absolute z-50 left-0 right-0 mt-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg overflow-hidden">
              <li
                v-for="loc in locations"
                :key="loc.place_id"
                @click="selectLocation(loc)"
                class="px-4 py-3 text-sm hover:bg-orange-50 dark:hover:bg-orange-500/10 cursor-pointer transition border-b border-slate-100 dark:border-slate-800 last:border-none"
              >
                {{ formatLocationName(loc) }}
              </li>
            </ul>
          </div>

          <div class="flex items-center gap-2 w-full sm:w-auto justify-end">
            <button
              @click="units = units === 'si' ? 'us' : 'si'"
              class="px-3 py-2 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 rounded-xl text-xs font-semibold transition flex items-center gap-1.5"
            >
              <Thermometer class="w-4 h-4 text-orange-500" />
              <span>{{ units === 'si' ? 'Metric (°C)' : 'Imperial (°F)' }}</span>
            </button>
            <button
              @click="toggleDark"
              class="p-2 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 rounded-xl transition"
              :title="isDark ? 'Switch to light mode' : 'Switch to dark mode'"
              :aria-label="isDark ? 'Switch to light mode' : 'Switch to dark mode'"
            >
              <component :is="isDark ? Sun : Moon" class="w-4 h-4 text-orange-500" />
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
              :class="alert.severity === 'severe' || alert.severity === 'warning' ? 'bg-red-50 border-red-200 dark:bg-red-500/10 dark:border-red-500/30' : 'bg-amber-50 border-amber-200 dark:bg-amber-500/10 dark:border-amber-500/30'"
            >
              <div @click="expandedAlerts[index] = !expandedAlerts[index]" class="flex items-start justify-between cursor-pointer gap-3">
                <div class="flex items-start gap-3">
                  <AlertTriangle class="w-6 h-6 shrink-0 mt-0.5" :class="alert.severity === 'severe' ? 'text-red-600 dark:text-red-400' : 'text-amber-500'" />
                  <div>
                    <h4 class="font-semibold text-sm flex items-center gap-2" :class="alert.severity === 'severe' ? 'text-red-900 dark:text-red-200' : 'text-amber-900 dark:text-amber-200'">
                      {{ alert.title }}
                      <span class="text-xs font-normal underline opacity-80">(Click to {{ expandedAlerts[index] ? 'collapse' : 'expand' }})</span>
                    </h4>
                    <p v-if="!expandedAlerts[index]" class="text-xs mt-1 line-clamp-1" :class="alert.severity === 'severe' ? 'text-red-700 dark:text-red-300' : 'text-amber-700 dark:text-amber-300'">{{ alert.description }}</p>
                  </div>
                </div>
                <component :is="expandedAlerts[index] ? ChevronUp : ChevronDown" class="w-5 h-5 shrink-0" :class="alert.severity === 'severe' ? 'text-red-600 dark:text-red-400' : 'text-amber-500'" />
              </div>
              <div v-if="expandedAlerts[index]" class="mt-3 pt-3 border-t text-xs space-y-2 whitespace-pre-line leading-relaxed" :class="alert.severity === 'severe' ? 'border-red-200 text-red-700 dark:border-red-500/30 dark:text-red-300' : 'border-amber-200 text-amber-700 dark:border-amber-500/30 dark:text-amber-300'">
                {{ alert.description }}
              </div>
            </div>
          </div>

          <!-- Current Conditions Card -->
          <div class="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-3xl shadow-sm border border-slate-200 dark:border-slate-800 grid grid-cols-1 md:grid-cols-5 gap-6">
            <!-- Hero: location, icon, temperature -->
            <div class="md:col-span-2 flex flex-col justify-center gap-4">
              <div class="flex items-center gap-2 text-slate-500 dark:text-slate-400 text-sm font-medium">
                <Compass class="w-4 h-4 text-orange-500 shrink-0" />
                <span>{{ selectedLocation ? formatLocationName(selectedLocation) : '' }}</span>
              </div>
              <div class="flex items-center gap-4">
                <component :is="getWeatherIconComponent(weather.currently.icon)" class="w-20 h-20 text-orange-500 shrink-0" />
                <span class="text-6xl sm:text-7xl font-bold tracking-tight">
                  {{ formatTemp(weather.currently.temperature) }}°
                </span>
              </div>
              <div class="space-y-1">
                <span class="text-lg font-medium block">{{ weather.currently.summary }}</span>
                <p class="text-xs text-slate-500 dark:text-slate-400">
                  Feels like {{ formatTemp(weather.currently.apparentTemperature ?? weather.currently.temperature) }}°
                  <span v-if="weather.daily?.data?.[0]">
                    · H {{ formatTemp(weather.daily.data[0].temperatureHigh) }}° · L {{ formatTemp(weather.daily.data[0].temperatureLow ?? weather.daily.data[0].temperatureMin) }}°
                  </span>
                </p>
              </div>
            </div>

            <!-- Metrics Grid beside the hero -->
            <div class="md:col-span-3 grid grid-cols-2 sm:grid-cols-3 gap-3 content-center pt-6 border-t md:pt-0 md:pl-6 md:border-t-0 md:border-l border-slate-100 dark:border-slate-800">
              <div
                v-for="metric in currentMetrics"
                :key="metric.label"
                class="bg-slate-50 dark:bg-slate-800/60 p-3 rounded-2xl border border-slate-100 dark:border-slate-700/60 flex flex-col gap-2"
              >
                <div class="flex items-center gap-1.5 text-slate-400 text-xs">
                  <component :is="metric.icon" class="w-3.5 h-3.5" :class="metric.color" />
                  <span>{{ metric.label }}</span>
                </div>
                <span class="text-base font-semibold">
                  {{ metric.value }} <span v-if="metric.unit" class="text-[10px] font-normal text-slate-500 dark:text-slate-400">{{ metric.unit }}</span>
                </span>
              </div>
            </div>
          </div>

          <!-- Minutely Precipitation Forecast (Unified Timeline) -->
          <div v-if="hasPrecipitation" class="bg-blue-50/50 dark:bg-blue-500/10 border border-blue-200 dark:border-blue-500/30 rounded-3xl p-6 shadow-sm">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center gap-2 text-blue-800 dark:text-blue-200 text-sm font-semibold">
                <CloudRain class="w-5 h-5 text-blue-500 dark:text-blue-400" />
                <span>{{ weather.minutely.summary }}</span>
              </div>
            </div>

            <div class="bg-white/80 dark:bg-slate-900/80 border border-blue-100 dark:border-blue-500/20 rounded-2xl p-4">
              <div class="flex items-end gap-1 overflow-x-auto pb-2 h-20 scrollbar-thin">
                <div
                  v-for="min in weather.minutely.data.filter((_, i) => i % 2 === 0)"
                  :key="min.time"
                  class="flex-1 flex flex-col items-center justify-end gap-1 min-w-[12px] h-full group relative"
                  :title="`${formatHour(min.time)}: ${Math.round(min.precipProbability * 100)}% chance, Intensity: ${min.precipIntensity} mm/h`"
                >
                  <div
                    class="w-full rounded-t transition-all"
                    :class="getPrecipColor(min)"
                    :style="{ height: `${Math.max(8, Math.min(100, (min.precipIntensity / 10) * 100))}%` }"
                  ></div>
                </div>
              </div>
              <div class="flex justify-between text-[10px] text-slate-400 mt-2 pt-2 border-t border-slate-100 dark:border-slate-800">
                <span>Now</span>
                <span>+30 min</span>
                <span>+60 min</span>
              </div>

              <!-- Minutely Legend Underneath -->
              <div class="flex flex-wrap items-center justify-center gap-x-4 gap-y-2 mt-3 pt-3 border-t border-blue-100/60 dark:border-blue-500/20 text-[11px] text-slate-600 dark:text-slate-300">
                <span class="font-semibold text-slate-700 dark:text-slate-200">Legend:</span>
                <div class="flex items-center gap-1.5 whitespace-nowrap"><span class="w-3 h-3 rounded bg-green-200 shrink-0"></span><span>Very Light</span></div>
                <div class="flex items-center gap-1.5 whitespace-nowrap"><span class="w-3 h-3 rounded bg-green-400 shrink-0"></span><span>Light</span></div>
                <div class="flex items-center gap-1.5 whitespace-nowrap"><span class="w-3 h-3 rounded bg-yellow-400 shrink-0"></span><span>Medium</span></div>
                <div class="flex items-center gap-1.5 whitespace-nowrap"><span class="w-3 h-3 rounded bg-red-600 shrink-0"></span><span>Heavy</span></div>
              </div>
            </div>
          </div>

          <!-- Hourly Forecast Horizontal Scroll -->
          <div class="bg-white dark:bg-slate-900 p-6 rounded-3xl shadow-sm border border-slate-200 dark:border-slate-800">
            <h3 class="text-sm font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Hourly Forecast</h3>
            <div class="flex gap-3 overflow-x-auto pb-2 scrollbar-thin">
              <div
                v-for="hour in weather.hourly.data.slice(0, 24)"
                :key="hour.time"
                class="flex flex-col items-center p-3 min-w-[76px] bg-slate-50 dark:bg-slate-800/60 rounded-2xl border border-slate-100 dark:border-slate-700/60 shrink-0"
              >
                <span class="text-xs text-slate-500 dark:text-slate-400">{{ formatHour(hour.time) }}</span>
                <component :is="getWeatherIconComponent(hour.icon)" class="w-6 h-6 text-orange-500 my-2" />
                <span class="text-sm font-bold">{{ formatTemp(hour.temperature) }}°</span>
                <span class="mt-1 flex items-center gap-0.5 text-[11px] text-blue-600 dark:text-blue-400">
                  <Droplets class="w-3 h-3" />
                  {{ Math.round((hour.precipProbability ?? 0) * 100) }}%
                </span>
                <span v-if="formatPrecipAmount(hour.precipAccumulation, hour.precipType)" class="text-[10px] text-slate-500 dark:text-slate-400 whitespace-nowrap">
                  {{ formatPrecipAmount(hour.precipAccumulation, hour.precipType) }}
                </span>
              </div>
            </div>
          </div>

          <!-- 7-Day Forecast Grid (Expandable Day/Night) -->
          <div class="bg-white dark:bg-slate-900 p-6 rounded-3xl shadow-sm border border-slate-200 dark:border-slate-800">
            <h3 class="text-sm font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">7-Day Forecast</h3>
            <div class="space-y-3">
              <div
                v-for="(day, index) in weather.daily.data"
                :key="day.time"
                class="bg-slate-50 dark:bg-slate-800/60 rounded-2xl border border-slate-100 dark:border-slate-700/60 overflow-hidden transition"
              >
                <!-- Summary Row (Clickable to Expand) -->
                <div
                  @click="expandedDays[index] = !expandedDays[index]"
                  class="flex items-center justify-between p-4 cursor-pointer hover:bg-slate-100/60 dark:hover:bg-slate-700/40 transition"
                >
                  <div class="w-32">
                    <span class="font-medium text-slate-700 dark:text-slate-200 block">{{ formatDay(day.time) }}</span>
                    <span class="text-xs text-slate-400">{{ formatDate(day.time) }}</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <component :is="getWeatherIconComponent(day.icon)" class="w-5 h-5 text-orange-500" />
                    <span class="text-xs text-slate-500 dark:text-slate-400 hidden sm:inline truncate max-w-xs">{{ day.summary }}</span>
                  </div>
                  <div class="flex items-center gap-4 text-sm">
                    <span
                      v-if="formatAqi(day.airQualityIndex) !== null"
                      class="hidden sm:inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-medium"
                      :class="getAqiStyle(formatAqi(day.airQualityIndex)).classes"
                      :title="`Air Quality: ${getAqiStyle(formatAqi(day.airQualityIndex)).label}`"
                    >
                      <Activity class="w-3 h-3" />
                      AQI {{ formatAqi(day.airQualityIndex) }}
                    </span>
                    <div class="flex items-center gap-2">
                      <span class="font-bold">{{ formatTemp(day.temperatureHigh) }}°</span>
                      <span class="text-slate-400">{{ formatTemp(day.temperatureLow ?? day.temperatureMin) }}°</span>
                    </div>
                    <component :is="expandedDays[index] ? ChevronUp : ChevronDown" class="w-4 h-4 text-slate-400" />
                  </div>
                </div>

                <!-- Expanded Day / Night Details Section -->
                <div v-if="expandedDays[index]" class="p-4 border-t border-slate-200/60 dark:border-slate-700/60 bg-white/50 dark:bg-slate-900/40 grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                  <div
                    v-for="part in getDayParts(index, day)"
                    :key="part.label"
                    class="p-4 border rounded-xl flex flex-col gap-3"
                    :class="dayPartStyles[part.isNight ? 'night' : 'day'].card"
                  >
                    <span class="text-[11px] font-semibold uppercase tracking-wider" :class="dayPartStyles[part.isNight ? 'night' : 'day'].label">{{ part.label }}</span>

                    <div class="flex items-center gap-3">
                      <component :is="getWeatherIconComponent(part.icon)" class="w-10 h-10 shrink-0" :class="dayPartStyles[part.isNight ? 'night' : 'day'].icon" />
                      <span class="text-3xl font-bold text-slate-800 dark:text-slate-100">{{ formatTemp(part.temperature) }}°</span>
                    </div>

                    <p class="text-slate-600 dark:text-slate-300 leading-relaxed">{{ part.summary }}</p>

                    <dl class="mt-auto grid grid-cols-2 gap-x-4 gap-y-1.5 pt-3 border-t text-[11px]" :class="dayPartStyles[part.isNight ? 'night' : 'day'].divider">
                      <div class="flex justify-between gap-2">
                        <dt class="text-slate-500 dark:text-slate-400">Precip</dt>
                        <dd class="font-semibold text-slate-700 dark:text-slate-200 whitespace-nowrap">
                          {{ Math.round((part.precipProbability ?? 0) * 100) }}%<span v-if="part.precipAmount" class="font-normal text-slate-500 dark:text-slate-400"> · {{ part.precipAmount }}</span>
                        </dd>
                      </div>
                      <div class="flex justify-between gap-2">
                        <dt class="text-slate-500 dark:text-slate-400">Wind</dt>
                        <dd class="font-semibold text-slate-700 dark:text-slate-200 whitespace-nowrap">{{ getWindDirection(part.windBearing) }} {{ formatWindSpeed(part.windSpeed) }} {{ units === 'si' ? 'km/h' : 'mph' }}</dd>
                      </div>
                      <div class="flex justify-between gap-2">
                        <dt class="text-slate-500 dark:text-slate-400">Humidity</dt>
                        <dd class="font-semibold text-slate-700 dark:text-slate-200">{{ Math.round((part.humidity ?? 0) * 100) }}%</dd>
                      </div>
                      <div class="flex justify-between gap-2">
                        <dt class="text-slate-500 dark:text-slate-400">Dew Point</dt>
                        <dd class="font-semibold text-slate-700 dark:text-slate-200">{{ formatTemp(part.dewPoint) }}°</dd>
                      </div>
                      <div v-if="!part.isNight" class="flex justify-between gap-2">
                        <dt class="text-slate-500 dark:text-slate-400">UV Index</dt>
                        <dd class="font-semibold text-slate-700 dark:text-slate-200">{{ Math.round(part.uvIndex) ?? 'N/A' }}</dd>
                      </div>
                      <div v-else class="flex justify-between gap-2">
                        <dt class="text-slate-500 dark:text-slate-400">Visibility</dt>
                        <dd class="font-semibold text-slate-700 dark:text-slate-200">{{ formatVisibility(part.visibility) }} {{ units === 'si' ? 'km' : 'mi' }}</dd>
                      </div>
                    </dl>
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
