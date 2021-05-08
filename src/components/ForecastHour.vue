<template>
  <ul class="forecast">
    <li class="hour" v-for="(hour, ind) in hourly2(hourly)">
    <div>{{hourOfDay(hour.time * 1000, store.weather.timezone) }}</div>
    <div class="icon">
      <WeatherIcon :icon="hour.icon"></WeatherIcon>
    </div>
    <strong>{{ Math.round(hour.temperature) }}°</strong>
     <div>{{ Math.round(hour.precipProbability * 100) }}%</div>
    </li>
  </ul>
</template>

<script>
  import WeatherIcon from './WeatherIcon'
  import moment from 'moment'
  import 'moment-timezone'

  export default {
    name: 'forecast',
    components: {
      WeatherIcon
    },
    computed: {
      store () {
        return this.$store.state
      },
      hourly () {
        return this.$store.state.weather.hourly.data
      }
    },
    methods: {
      hourOfDay (time, zone) {
        return moment(time).tz(zone).format('h a')
      },
      hourly2 (hourly) {
        var hourly2 = []
        var i = []
        for (i = 0; i < 16; i = i + 2) {
          hourly2.push(hourly[i])
        }
        return hourly2
      }
    }
  }
</script>

<style lang="scss" scoped>
@import '../scss/_vars.scss';

.forecast {
  border-top: 1px solid #dedede;
  display: flex;
  flex-wrap: wrap;
  margin-top: 16px;
  padding-top: 16px;

  li {
    flex: 1;
  }

  .hour {
    color: $accent;
    font-size: 16px;
    line-height: 1.6;
    text-align: center;

    @media(max-width: 850px) {
      flex: 0 0 25%;
      margin-top: 8px;
    }
  }

  .icon {
    height: 32px;
    margin: 0 auto;
    width: 32px;
  }
}
</style>
