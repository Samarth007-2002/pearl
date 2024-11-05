FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# Build the application if needed
# RUN npm run build

FROM node:20-alpine
WORKDIR /app

COPY --from=build /app .

EXPOSE 9000

CMD npm run start
