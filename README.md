# Weather Vue
Weather app using Vue 3, Tailwind CSS, OpenStreetMap Nominatim geocoding, and [Pirate Weather](https://pirateweather.net).

![Weather Vue screenshot](screenshot.png)

# Status
This project is currently dormant. I'll be keeping it around in case it's ever useful to someone, but for now, the main Pirate Weather homepage is [MerrySky](https://merrysky.net/), since it's much better than this was!

## Features
* Location search powered by OpenStreetMap Nominatim
* Current conditions with wind, AQI, pressure, dew point, humidity and visibility
* Minute-by-minute precipitation timeline with an intensity legend (shown when precipitation is expected)
* 24-hour forecast with chance of precipitation and expected amount
* 7-day forecast with US AQI colour-coded badges and expandable day/night breakdowns
* Weather alerts
* Metric / Imperial toggle
* Light / Dark mode toggle (follows your system setting until changed)

## Getting Started
You'll need a free [Pirate Weather API key](https://pirateweather.net/en/latest/#getting-started).

``` bash
# clone the repo
git clone https://github.com/Pirate-Weather/weather-vue.git
cd weather-vue
# install dependencies
npm install
# copy the example environment file and add your Pirate Weather API key
cp .env.example .env
```

Then set your key in `.env`:
```
VITE_PIRATE_WEATHER_API_KEY=your_actual_pirate_weather_key_here
```

## Build Setup
``` bash
# serve with hot reload
npm run dev
# build for production
npm run build
# preview the production build locally
npm run preview
```

### API Key Visibility
This app calls Pirate Weather directly from the browser, so your API key is **not private**. Because it's a `VITE_` variable, it is included in the built JavaScript, and it appears in the request URL in the browser's developer tools (Network tab). No build setting or browser option can hide it.

This is fine for local use or a personal deployment. If you host it publicly, anyone could copy the key and use your quota. To keep the key private, run a small server-side proxy (for example a Cloudflare Worker, a Netlify/Vercel function, or a reverse proxy on your own server) that adds the key to the request, and point the app at the proxy instead of `api.pirateweather.net`.

### Mock Data
To work on the layout without using API calls, set `useMock` to `true` in `src/App.vue`. Weather data will then be loaded from `public/mock-weather.json` instead of the Pirate Weather API.

## Built With
* [Vue.js](https://vuejs.org/)
* [Vite](https://vite.dev/)
* [Tailwind CSS](https://tailwindcss.com/)
* [Lucide Icons](https://lucide.dev/)
* [Pirate Weather API](https://pirateweather.net)
* [OpenStreetMap Nominatim](https://nominatim.org/)

## License
This project is licensed under the MIT License - see the LICENSE.md file for details
