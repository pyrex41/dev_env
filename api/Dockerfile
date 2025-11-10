# Multi-stage Dockerfile for Node/TypeScript API

# Base stage
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache curl
RUN corepack enable && corepack prepare pnpm@latest --activate

# Dependencies stage
FROM base AS dependencies
COPY package.json ./
COPY pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install

# Development stage
FROM base AS development
COPY package.json ./
COPY pnpm-lock.yaml* ./
RUN pnpm install
COPY . .
EXPOSE 8000 9229
CMD ["pnpm", "run", "dev"]

# Build stage
FROM dependencies AS build
COPY . .
RUN pnpm run build

# Production stage
FROM base AS production
ENV NODE_ENV=production
COPY package.json ./
COPY pnpm-lock.yaml* ./
RUN pnpm install --prod --frozen-lockfile || pnpm install --prod
COPY --from=build /app/dist ./dist
EXPOSE 8000
CMD ["node", "dist/index.js"]
