# Multi-purpose Dockerfile for AppointmentService
# Uses Node 18 (Alpine) and runs the app as a non-root user

FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Install only production dependencies first
COPY package.json package-lock.json* ./
RUN npm ci --production --no-audit --no-fund

# Copy source
COPY . .

# Use a non-root user
RUN addgroup -S app && adduser -S app -G app
USER app

# Environment defaults
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Start the service
CMD ["npm", "start"]
