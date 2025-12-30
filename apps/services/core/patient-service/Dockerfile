FROM node:20-alpine AS builder

RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package*.json ./
COPY nx.json ./
COPY tsconfig*.json ./

RUN npm install --legacy-peer-deps

COPY . .

RUN npx nx build patient-service --configuration=production


FROM node:20-alpine AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

COPY package*.json ./
RUN npm install --only=production --legacy-peer-deps

COPY --from=builder --chown=nestjs:nodejs /app/dist/apps/services/core/patient-service ./dist

ENV NODE_ENV production
ENV PORT 3001

USER nestjs

EXPOSE 3001

CMD ["node", "dist/main.js"]