# Multi-stage Dockerfile for React/TypeScript Frontend with Vite

# Base stage
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache curl
RUN corepack enable && corepack prepare pnpm@latest --activate

# Dependencies stage
FROM base AS dependencies
COPY package*.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install

# Development stage
FROM base AS development
COPY package*.json pnpm-lock.yaml* ./
RUN pnpm install
COPY . .
EXPOSE 3000
CMD ["pnpm", "run", "dev"]

# Build stage
FROM dependencies AS build
COPY . .
RUN pnpm run build

# Production stage
FROM nginx:alpine AS production
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
