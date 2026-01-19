# ==============================================================================
# DOCKERFILE: API GATEWAY (PRODUCTION)
# ==============================================================================

FROM node:18-alpine

RUN apk add --no-cache dumb-init

WORKDIR /app

ENV NODE_ENV production

# Copy gateway specific package.json
COPY dist/apps/services/api-gateway/package*.json ./

RUN npm ci --omit=dev && npm cache clean --force

COPY dist/apps/services/api-gateway/main.js ./

USER node

EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["dumb-init", "node", "main.js"]