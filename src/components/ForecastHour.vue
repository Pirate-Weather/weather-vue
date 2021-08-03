<template>
  <div style="background-color:#E2E5E9; text-align: center;"> <strong> Hourly</strong> 
  <ul class="forecast">
    <li class="hour" v-for="(hour, ind) in hourly2(hourly)">
        <div>{{hourOfDay(hour.time * 1000, store.weather.timezone) }}</div>
        <div class="icon">
          <WeatherIcon :icon="hour.icon"></WeatherIcon>
        </div>
        <strong>{{ Math.round(hour.temperature) }}°</strong>
        <div>{{ Math.round(hour.precipProbability * 100) }}%</div>
        <div v-if="hour.icon == 'rain'">{{ Math.round(hour.precipAccumulation * 100, 2) / 10 }} {{ precpLabelRain }}</div>      
        <div v-else-if="hour.icon == 'snow'">{{ Math.round(hour.precipAccumulation * 100, 2) / 100 }} {{ precpLabelSnow }}</div>      
        <div v-else>{{ 0 }} {{ precpLabelRain }}</div>
    </li>
  </ul>
  </div>
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
      },
      precpLabelRain () {
        switch (this.store.units) {
          case 'us':
            return 'in'
          case 'ca':
            return 'mm'
        }
      },
      precpLabelSnow () {
        switch (this.store.units) {
          case 'us':
            return 'in'
          case 'ca':
            return 'cm'
        }
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
