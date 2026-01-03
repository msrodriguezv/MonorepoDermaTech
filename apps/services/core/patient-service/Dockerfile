# STAGE 1: Builder
FROM node:20-alpine AS builder

# Install compatibility dependencies (required for C++ libraries like Kafka or Sharp)
RUN apk add --no-cache libc6-compat python3 make g++

WORKDIR /app

# Copy monorepo configuration files
COPY package*.json ./
COPY nx.json ./
COPY tsconfig*.json ./

# Install ALL dependencies (including devDependencies to allow compilation)
RUN npm install --legacy-peer-deps

# Copy full source code
COPY . .

# Build ONLY the patient-service
# This generates the output at dist/apps/services/core/patient-service
RUN npx nx build patient-service --configuration=production


# STAGE 2: Runner (Lightweight final image)
FROM node:20-alpine AS runner
WORKDIR /app

# Create system user for security (Best Practices)
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

# Copy root package.json to install production dependencies
COPY package*.json ./

# Install only production dependencies (saves space)
RUN npm install --only=production --legacy-peer-deps

# Copy the build generated in the previous stage
COPY --from=builder --chown=nestjs:nodejs /app/dist/apps/services/core/patient-service ./dist

# Environment variables
ENV NODE_ENV production
ENV PORT 3001

# Switch to non-privileged user
USER nestjs

EXPOSE 3001

CMD ["node", "dist/main.js"]