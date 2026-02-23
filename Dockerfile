FROM node:20-alpine3.19

# Patch Alpine OS packages to reduce vulnerabilities
RUN apk update && apk upgrade --no-cache

# Create app directory
WORKDIR /usr/src/app

# Copy package files first (for Docker layer caching)
COPY package.json package-lock.json* ./

# Install only production Node dependencies
# AND automatically fix vulnerabilities
RUN npm ci --production && \
    npm audit fix --production || true

# Copy application source
COPY . .

# Use a non-root user
RUN addgroup -S app && adduser -S app -G app
USER app

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["npm", "start"]
