var merge = require('webpack-merge')
var prodEnv = require('./prod.env')
var keys = require('../keys')

module.exports = merge(prodEnv, {
  NODE_ENV: '"development"',
  API_KEY: keys.dev,
  API_URL: {
    geocode: '"https://pirateweather-api.herokuapp.com/geocode/v1/json?"',
    weather: '"https://pirateweather-api.herokuapp.com/weather/v1/json?"'
  }
})
