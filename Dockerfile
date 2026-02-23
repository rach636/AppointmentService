FROM node:20-alpine3.19

# Patch Alpine OS packages first to reduce vulnerabilities
RUN apk update && apk upgrade --no-cache

# Create app directory
WORKDIR /usr/src/app

# Copy package files first (for Docker caching)
COPY package.json package-lock.json* ./

# Install only production Node dependencies
RUN npm ci --production --no-audit --no-fund

# Copy application source
COPY . .

# Use a non-root user
RUN addgroup -S app && adduser -S app -G app
USER app

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["npm", "start"]
