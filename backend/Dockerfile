# --- Builder ---------------------------------------------------------------
FROM node:20-bookworm-slim AS builder
WORKDIR /app

COPY package.json tsconfig.json ./
RUN npm install --no-audit --no-fund

COPY src ./src
RUN npm run build

# --- Runtime ---------------------------------------------------------------
FROM node:20-bookworm-slim AS runtime
WORKDIR /app

# yt-dlp needs python3 + ffmpeg. We pin yt-dlp to a recent release; bump it
# in Renovate later. The python3-pip route is reliable enough for now.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        ffmpeg \
        ca-certificates \
        curl \
    && pip3 install --break-system-packages --no-cache-dir 'yt-dlp==2025.2.19' \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production

COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund

COPY --from=builder /app/dist ./dist

EXPOSE 3000
CMD ["node", "dist/server.js"]
