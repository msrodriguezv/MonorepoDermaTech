# ==============================================================================
# DOCKERFILE: AUTH SERVICE (PRODUCTION)
# Context: Requires 'nx build auth-service --prod' to be run first.
# Security: Runs as non-root user 'node'.
# ==============================================================================

FROM node:18-alpine

# Install dumb-init to handle PID 1 signals correctly
RUN apk add --no-cache dumb-init

WORKDIR /app

# Set NODE_ENV to production to enable optimizations
ENV NODE_ENV production

# 1. Dependency Layer
# Copy package.json from the build output (Assumes build context is root)
COPY dist/apps/services/core/auth-service/package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev && npm cache clean --force

# 2. Application Layer
COPY dist/apps/services/core/auth-service/main.js ./

# 3. Security & Networking
# Use non-root user for security
USER node

EXPOSE 3000

# Healthcheck to ensure the service is responsive
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/api/health || exit 1

# Start using dumb-init
CMD ["dumb-init", "node", "main.js"]
