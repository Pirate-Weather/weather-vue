FROM node:lts-alpine as api

RUN apk update
RUN apk add git

# make the 'app' folder the current working directory
WORKDIR /app

# copy both 'package.json' and 'package-lock.json' (if available)
COPY package*.json ./

# install project dependencies
RUN npm install

# copy project files and folders to the current working directory (i.e. 'app' folder)
COPY . .

# build app for production with minification
#RUN npm run build

# replace dark sky with pirate weather
RUN sed -i 's/api.darksky.net/api.pirateweather.net/g' /app/node_modules/dark-sky/dark-sky-api.js

EXPOSE $PORT
CMD [ "node", "api/app.js" ]


FROM node:lts-alpine as web

RUN apk update
RUN apk add git

# make the 'app' folder the current working directory
WORKDIR /app

# copy both 'package.json' and 'package-lock.json' (if available)
COPY package*.json ./

# install project dependencies
RUN npm install

# copy project files and folders to the current working directory (i.e. 'app' folder)
COPY . .

# build app for production with minification
#RUN npm run build

# replace dark sky with pirate weather
RUN sed -i 's/api.darksky.net/api.pirateweather.net/g' /app/node_modules/dark-sky/dark-sky-api.js

EXPOSE $PORT
CMD [ "node", "build/dev-server.js" ]
