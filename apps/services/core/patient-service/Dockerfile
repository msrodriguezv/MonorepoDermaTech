# ==============================================================================
# DOCKERFILE: PATIENT SERVICE (PRODUCTION)
# Context: Requires 'nx build patient-service --prod' artifact.
# ==============================================================================

FROM node:18-alpine

# 1. System Dependenciess
# Install dumb-init to handle PID 1 signals correctly
RUN apk add --no-cache dumb-init

WORKDIR /app

# Set NODE_ENV to production for performance optimizations
ENV NODE_ENV production

# 2. Dependency Layer
# Copy package.json from the specific service build output
COPY dist/apps/services/core/patient-service/package*.json ./

# Install ONLY production dependencies (Clean install)
RUN npm ci --omit=dev && npm cache clean --force

# 3. Application Layer
# Copy the compiled main.js bundle
COPY dist/apps/services/core/patient-service/main.js ./

# 4. Security & Networking
# Switch to non-root user
USER node

EXPOSE 3000

# Healthcheck (Optional but recommended)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/api/health || exit 1

# 5. Runtime
CMD ["dumb-init", "node", "main.js"]