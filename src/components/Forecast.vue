<template>
   <div style="text-align: center;"> <strong> Daily</strong> 
  <ul class="forecast">
    <li class="day" v-for="day in daily">
      <div>{{ dayOfWeek(day.time * 1000, store.weather.timezone) }}</div>
      <div class="icon">
        <WeatherIcon :icon="day.icon"></WeatherIcon>
      </div>
      <strong>{{ Math.round(day.temperatureMax) }}°</strong>
      <div>{{ Math.round(day.temperatureMin) }}°</div>
      <div>{{ Math.round(day.precipProbability * 100) }}%</div>
      <div v-if="day.icon == 'rain'">{{ Math.round(day.precipAccumulation * 100, 2) / 10 }} {{ precpLabelRain }}</div>      
      <div v-else-if="day.icon == 'snow'">{{ Math.round(day.precipAccumulation * 100, 2) / 100 }} {{ precpLabelSnow }}</div>      
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
      daily () {
        return this.$store.state.weather.daily.data
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
      dayOfWeek (time, zone) {
        return moment(time).tz(zone).format('ddd')
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

  .day {
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
