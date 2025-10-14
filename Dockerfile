# syntax=docker/dockerfile:1.4

# ---- Build Stage ----
FROM node:16.17.0-alpine AS builder

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

# Avoid storing sensitive data (like API keys) in image layers
# Use build-time secrets or pass ENV vars at runtime instead
ARG TMDB_V3_API_KEY
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"

RUN yarn build

# ---- Runtime Stage ----
FROM nginx:stable-alpine

WORKDIR /usr/share/nginx/html
RUN rm -rf ./*

# Copy the built frontend files
COPY --from=builder /app/dist .

EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]
