var keys = require('../keys')

module.exports = {
  NODE_ENV: '"production"',
  API_KEY: keys.prod,
  API_URL: {
    geocode: '"https://pirateweather-api.herokuapp.com/geocode/v1/json?"',
    weather: '"https://pirateweather-api.herokuapp.com/weather/v1/json?"'
  }
}
