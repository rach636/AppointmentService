FROM node:20-bookworm-slim AS deps

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force

FROM gcr.io/distroless/nodejs20-debian12:nonroot

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

EXPOSE 3002

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["node","-e","require('http').get('http://localhost:3002/api/v1/health', (r) => { if (r.statusCode !== 200) process.exit(1); }).on('error', () => process.exit(1))"]

CMD ["src/index.js"]
