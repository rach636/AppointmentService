FROM node:20-bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force

COPY . .

USER node

EXPOSE 3002

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3002/api/v1/health', (r) => {if (r.statusCode !== 200) process.exit(1)})"

CMD ["npm", "start"]
