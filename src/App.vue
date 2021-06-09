<template>
  <div id="app">
    <div class="weather-card">
      <Search ref="search"></Search>

      <div class="weather" v-if="store.appStatus.state === 'loaded'">
        <Current class="fadeIn"></Current>
        <ForecasMinute class="fadeIn" ></ForecasMinute>
        <ForecastHour class="fadeIn" style="margin-top: 25px"></ForecastHour>
        <Forecast class="fadeIn" style="margin-top: 25px"></Forecast>
        <div class="img-container" style="margin-top: 25px">
            <a href="https://pirateweather.net" target="_blank"><img src="./assets/home-imagec.png" alt="PirateWeather" style="height: 60px !important" ></a>                     
            <a href="https://www.buymeacoffee.com/pirateweather" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>             
            <iframe src="https://github.com/sponsors/alexander0042/button" title="Sponsor alexander0042" height="35" width="116" style="border: 0;"></iframe>
        </div>
      </div>
      <Credits class="credits" v-else-if="store.appStatus.state === 'credits'"></Credits>

      <div :class="store.appStatus.state" class="loading-or-error" v-else>
        <span>{{ store.appStatus.message }}</span>
        <div class="spinner" v-if="store.appStatus.state === 'loading'"></div>
      </div>

      <div class="footer">
        <button class="refresh" title="Refresh" @click="fetchWeather">
          <div v-if="store.weather.currently">
            <IconRefresh></IconRefresh>
            <span>Last updated: {{ timestamp(store.weather.currently.time * 1000, store.weather.timezone)}}</span>
          </div>
        </button>

        <button class="credits" title="Credits" @click="credits">
          <IconHelp></IconHelp>
        </button>
      </div>
    </div>

    <Background></Background>
  </div>
</template>

<script>
  import Background from './components/Background'
  import Search from './components/Search'
  import Current from './components/Current'
  import Forecast from './components/Forecast'
  import ForecastHour from './components/ForecastHour'
  import ForecasMinute from './components/ForecastMinute'
  import Credits from './components/Credits'
  import IconRefresh from './assets/icons/ui/refresh.svg'
  import IconHelp from './assets/icons/ui/help.svg'
  import moment from 'moment'
  import 'moment-timezone'

  export default {
    name: 'app',
    components: {
      Background,
      Search,
      Current,
      Forecast,
      ForecastHour,
      ForecasMinute,
      Credits,
      IconRefresh,
      IconHelp
    },
    computed: {
      store () {
        return this.$store.state
      }
    },
    methods: {
      credits () {
        (this.store.appStatus.state === 'credits')
          ? this.$store.dispatch('appStatus', {state: 'loaded'})
          : this.$store.dispatch('appStatus', {state: 'credits'})
      },
      fetchWeather () {
        this.$store.dispatch('appStatus', {state: 'loading'})
        this.$store.dispatch('weather').then(() => {
          this.$store.dispatch('appStatus', {state: 'loaded'})
        })
      },
      timestamp (time, zone) {
        return moment(time).tz(zone).format('h:mm A')
      }
    },
    mounted () {
      (localStorage.units) ? this.$store.dispatch('units', localStorage.getItem('units')) : null
    }
  }
</script>

<style lang="scss">
@import 'scss/_base.scss';
@import 'scss/partials/_spinner.scss';
#app {
  align-items: center;
  display: flex;
  flex-direction: column;
  /*height: 100%;*/
  justify-content: center;

  @media(max-width: 850px) {
    height: initial;
  }
}

.img-container {
  text-align: center;
}

.weather-card {
  background-color: #fbfbfb;
  border-radius: 3px;
  box-shadow: 0px 0px 150px 0px rgba(0,0,0,0.5);
  color: #383842;
  display: flex;
  flex-direction: column;
  margin-top: 10vh;
  max-width: 800px;
  min-height: 650px;
  padding: 32px;
  position: relative;
  width: 100%;
  z-index: 1;

  > * {
    display: flex;
    flex-direction: column;
  }

  @media(max-width: 850px) {
    border-radius: 0;
    margin: 32px;
    max-width: 500px;
    padding: 16px;
  }

  @media(max-width: 550px) {
    box-shadow: none;
    margin: 0;
    max-width: 100%;
    min-height: 100vh;
  }
}
.weather {
  flex: none;
  margin-top: 16px;
  padding-bottom: 16px;
  position: relative;

  @media(max-width: 850px) {
    padding-bottom: 48px;
  }

  .current,
  .forecast {
    flex: none;

    @keyframes fadeIn {
      0% {
        opacity: 0;
      }
      100% {
        opacity: 1;
      }
    }

    svg {
      height: 100%;
      width: 100%;
    }
  }
}
.loading-or-error {
  align-items: center;
  flex: 1;
  justify-content: center;
  position: relative;

  .spinner {
    margin: -40px auto 0;
  }

  span {
    display: block;
    font-size: 16px;
    height: 16px;
    margin-top: -26px;
    position: absolute;
    text-align: center;
    top: 50%;
    width: 100%;
  }

  &.loading span {
    margin-top: 14px;
  }
}

.footer {
  align-items: center;
  bottom: 0;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  left: 0;
  margin: 0;
  opacity: .75;
  padding: 10px;
  position: absolute;
  width: 100%;

  button {
    display: flex;

    svg {
      fill: $accent;
      transition: 0.3s;
    }

    &:hover {
      svg {
        transform: rotate(45deg);
      }
    }
  }

  .refresh {
    div {
      align-items: center;
      display: flex;
    }

    span {
      color: $accent;
      font-size: 14px;
      margin-left: 5px;
    }
  }
}
</style>
