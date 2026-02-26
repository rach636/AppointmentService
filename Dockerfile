FROM node:20.11-alpine AS deps

WORKDIR /usr/src/app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force

FROM node:20.11-alpine

RUN apk update && apk upgrade --no-cache

WORKDIR /usr/src/app
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY . .

RUN addgroup -S app && adduser -S app -G app && chown -R app:app /usr/src/app
USER app

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["npm", "start"]
