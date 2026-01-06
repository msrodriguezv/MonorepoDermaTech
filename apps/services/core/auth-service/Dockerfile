# STAGE 1: Builder
# UPDATED: Using Node 20 (LTS) to support global Web Crypto API required by TypeORM
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

ARG PROJECT_NAME=auth-service
RUN npx nx build ${PROJECT_NAME} --prod

# STAGE 2: Runner
# UPDATED: Runtime also on Node 20
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/dist/apps/services/core/auth-service ./dist
COPY --from=builder /app/node_modules ./node_modules

# We define variable with backup. 
# If AUTH_SERVICE_PORT exists, use it. If not, use PORT If not, 3000.
ENV PORT=${AUTH_SERVICE_PORT:-${PORT:-3000}}
EXPOSE $PORT

CMD ["node", "dist/main"]