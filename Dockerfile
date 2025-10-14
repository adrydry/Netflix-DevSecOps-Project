# syntax=docker/dockerfile:1.4

# ---- Build Stage ----
FROM node:16.17.0-alpine AS builder

WORKDIR /app

# Copy dependencies files first for better caching
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Securely load the API key from a BuildKit secret (not stored in image)
RUN --mount=type=secret,id=tmdb_key \
    export TMDB_V3_API_KEY=$(cat /run/secrets/tmdb_key) && \
    VITE_APP_TMDB_V3_API_KEY=$TMDB_V3_API_KEY \
    VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3" \
    yarn build

# ---- Runtime Stage ----
FROM nginx:stable-alpine AS runtime

WORKDIR /usr/share/nginx/html

# Clean existing files
RUN rm -rf ./*

# Copy built frontend assets from builder stage
COPY --from=builder /app/dist .

# Expose web port
EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]
