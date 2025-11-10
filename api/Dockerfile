# Multi-stage Dockerfile for Node/TypeScript API

# Base stage
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache curl

# Dependencies stage
FROM base AS dependencies
COPY package*.json ./
RUN npm ci

# Development stage
FROM base AS development
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8000 9229
CMD ["npm", "run", "dev"]

# Build stage
FROM dependencies AS build
COPY . .
RUN npm run build

# Production stage
FROM base AS production
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production
COPY --from=build /app/dist ./dist
EXPOSE 8000
CMD ["node", "dist/index.js"]
