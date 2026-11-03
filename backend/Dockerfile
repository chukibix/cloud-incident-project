FROM node:24-alpine
RUN apk update && apk upgrade --no-cache
RUN npm install -g npm@latest

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "start:prod"]