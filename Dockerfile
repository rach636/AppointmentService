FROM node:18-alpine

WORKDIR /app
RUN apk add --no-cache dumb-init

COPY package*.json ./
RUN npm ci --only=production

COPY src ./src
COPY .sequelizerc ./

RUN mkdir -p logs
EXPOSE 3002

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3002/api/v1/health', (res) => { if (res.statusCode !== 200) throw new Error(res.statusCode) })"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/index.js"]
