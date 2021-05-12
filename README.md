# Weather Vue
Weather app using Vue.js, Google Maps Geocoding, and Pirate Weather-Dark Sky.
![alt tag](https://raw.githubusercontent.com/krestaino/weather-vue/master/static/images/og.jpg)

## Getting Started
This is a fork of [Weather Vue](https://github.com/krestaino/weather-vue) designed to work with [Pirate Weather](https://pirateweather.net) and Heroku via Docker. The app is otherwise the same, but split into a two-part dockerfile (web and api), each of which needs to be deployed to a separate instance. Key changes are separating the two parts into images, adding PORT references, and changing references from Dark Sky to Pirate Weaver (via sed). To deploy:
``` bash
# clone repo and API submodule
git clone https://github.com/alexander0042/weather-vue.git --recursive
cd weather-vue
# to fetch submodule if already cloned without the `--recursive` flag
git submodule update --init
# make copies of the two keys files from the examples (keys.js)
cp keys.js.example keys.js
cp api/keys.js.example api/keys.js
# edit the files with real keys 
# build both docker images
docker build -t weather-vue/weather-vue --target api -t weather:api .
docker build -t weather-vue/weather-vue --target web -t weather:web .
# Tag with Heroku app- both must be called web
docker tag weather:api registry.heroku.com/pirateweather-api/web
docker tag weather:web registry.heroku.com/pirate-web/web
# Push to Heroku
docker push registry.heroku.com/pirateweather-api/web
docker push registry.heroku.com/pirate-web/web
# Release images
heroku container:release -a pirateweather-api web
heroku container:release -a pirate-web web
```

## API Backend
The API backend for this project is a REST API using Node and Express. It's included in this project as a submodule and located in `./api`. The repo can be found [here](https://github.com/krestaino/weather-api). This backend API fetches geolocation data from Google and weather data from Dark Sky and returns it to the Weather Vue app.

Rename `./api/keys.js.example` to `./api/keys.js` and add your [Dark Sky API](https://darksky.net/dev/) and [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/get-api-key) keys.  

## Build Setup
Rename `./keys.js.example` to `./keys.js` and add your [Google Maps JavaScript API](https://developers.google.com/maps/documentation/javascript/get-api-key) keys. This API key is for the background map which uses the Google Maps JavaScript API. The `prod` key is exposed in your frontend code, so make sure you restrict the HTTP referrer to only allow requests from your production URL. This can be done in the Google API Console. The `dev` key is not included in production code, so it doesn't need the same restrictions.
``` bash
# install dependencies
npm install
# serve with hot reload at localhost:8080 and API at localhost:3000
npm run dev
# build for production with minification
npm run build
# build for production and view the bundle analyzer report
npm run build --report
```
For detailed explanation on how things work, check out the [Vue.js Webpack guide](http://vuejs-templates.github.io/webpack/) and [docs for vue-loader](http://vuejs.github.io/vue-loader).

## Built With
* [Vue.js](https://vuejs.org/)
* [Dark Sky API](https://darksky.net/dev/)
* [Google Maps JavaScript API](https://developers.google.com/maps/documentation/javascript/get-api-key)
* [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/get-api-key)
* [Google Places API](https://developers.google.com/places/web-service/autocomplete)

## License 
This project is licensed under the MIT License - see the LICENSE.md file for details