FROM node:20-alpine3.19

# Patch OS first
RUN apk update && apk upgrade --no-cache bash coreutils

WORKDIR /usr/src/app

# Copy package files
COPY package.json package-lock.json* ./

# Update Node modules and fix vulnerabilities inside the image
RUN npm install -g npm-check-updates && \
    ncu -u && \
    npm install --production --no-audit --no-fund && \
    npm audit fix --production || true

# Copy source code
COPY . .

# Non-root user
RUN addgroup -S app && adduser -S app -G app
USER app

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

CMD ["npm", "start"]
