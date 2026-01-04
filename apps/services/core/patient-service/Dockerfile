# --- STAGE 1: BUILDER ---
FROM node:20-alpine AS builder

WORKDIR /app

# Copy entire monorepo (necessary for Nx)
COPY . .

# Install dependencies and build the project
RUN npm ci
RUN npx nx build patient-service --prod
# Prune dependencies to keep image small
RUN npm prune --production

# --- STAGE 2: PRODUCTION ---
FROM node:20-alpine

# Create work directory and ensure 'node' user owns it
# This prevents permission issues when running the app
RUN mkdir -p /app && chown -R node:node /app

WORKDIR /app

# FIX 3: Copy files and assign ownership to 'node' user
# We use --chown=node:node so the non-privileged user can read them
COPY --chown=node:node --from=builder /app/dist/apps/services/core/patient-service ./dist
COPY --chown=node:node --from=builder /app/node_modules ./node_modules

ENV PORT=${PATIENT_SERVICE_PORT:-${PORT:-3001}}
EXPOSE $PORT

# --- SECURITY FIX ---
# Switch to 'node' user to avoid running as root
USER node

CMD ["node", "dist/main"]