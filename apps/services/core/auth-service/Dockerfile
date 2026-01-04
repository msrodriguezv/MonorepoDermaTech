FROM node:18-alpine AS builder
WORKDIR /app
COPY . .
RUN npm ci
RUN npx nx build auth-service --prod

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist/apps/services/core/auth-service ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/main"]