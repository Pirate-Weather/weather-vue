var keys = require('../keys')

module.exports = {
  NODE_ENV: '"production"',
  API_KEY: keys.prod,
  API_URL: {
    geocode: '"http://192.168.1.236:3000/geocode/v1/json?"',
    weather: '"http://192.168.1.236:3000/weather/v1/json?"'
  }
}
