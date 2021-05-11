<template>
    <div class="current" style="height: 200px; margin-top: 10px">
        <canvas id="minute-chart"></canvas>
    </div>
</template>
<script>
import Chart from 'chart.js'
import moment from 'moment'

export default {
  name: 'MinuteChart',
  data () {
    return {
      planetChartData: this.$store.state.weather.minutely.data
    }
  },
  mounted () {
//    console.log(this.precpLabel)
    var chart = this.createChart('minute-chart', this.minutely2(this.$store.state.weather.minutely.data, 'precipIntensity'), this.minutelyTime(this.$store.state.weather.minutely.data, 'time'), this.precpLabel)
//    var chart = this.createChart('minute-chart', this.minutely.precipProbability.values)
    chart.update()
  },
  computed: {
    store () {
      return this.$store.state
    },
    minutely () {
      return this.$store.state.weather.minutely.data
    },
    precpLabel () {
      switch (this.$store.state.units) {
        case 'us':
          return 'Precipitation (in)'
        case 'si':
          return 'Precipitation (mm)'
      }
    }
  },
  methods: {
    minuteOfDay (time, zone) {
      return moment(time).tz(zone).format('h:mm')
    },
    minutely2 (input, field) {
      var output = []
      var i = []
      for (i = 0; i < input.length; i = i + 5) {
        output.push(input[i][field])
      }
      return output
    },
    minutelyTime (input, field) {
      var output = []
      var i = []
      for (i = 0; i < input.length; i = i + 5) {
        output.push(this.minuteOfDay(input[i][field] * 1000, this.$store.state.weather.timezone))
      }
      return output
    },
    createChart (chartId, chartData, chartTimes, precpLabelText) {
      const ctx = document.getElementById(chartId)
      const myChart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: chartTimes,
          datasets: [
            {
              label: 'Precipitation',
              data: chartData,
              borderColor: '#003366'
            }
          ]
        },
        options: {
          responsive: true,
          lineTension: 1,
          scales: {
            yAxes: [{
              scaleLabel: {
                display: true,
                labelString: precpLabelText
              },
              ticks: {
                beginAtZero: true,
                padding: 40
              }
            }]
          },
          maintainAspectRatio: false
        }
      })
      return myChart // <<< this returns the created chart
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
