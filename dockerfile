# ==============================================================================
# MASTER DOCKERFILE - NESTJS MONOREPO SERVICES
# Purpose: Multi-stage build for any NestJS microservice within the Nx Monorepo.
# Usage: docker build --build-arg APP_NAME=auth-service --build-arg BUILD_PATH=dist/apps/services/core/auth-service .
# ==============================================================================

# ------------------------------------------------------------------------------
# STAGE 1: BUILDER
# Description: Compiles the TypeScript source code using Nx.
# ------------------------------------------------------------------------------
FROM node:20-alpine AS builder

# Set working directory for the build context
WORKDIR /app

# Install system dependencies required for native modules (e.g., node-gyp, python)
# Some NestJS libraries (like crypto or microservices) might need these.
RUN apk add --no-cache python3 make g++

# Copy package definition files first to leverage Docker layer caching
COPY package*.json ./
COPY nx.json ./
COPY tsconfig*.json ./

# Install ALL dependencies (including devDependencies) to enable compilation
RUN npm ci

# Copy the entire monorepo source code (Apps + Libs)
# Note: We rely on .dockerignore to exclude local node_modules/dist
COPY . .

# Argument: The name of the project as defined in project.json (e.g., auth-service)
ARG APP_NAME
# Validation: Ensure APP_NAME is provided to avoid silent failures
RUN if [ -z "$APP_NAME" ]; then echo "ERROR: APP_NAME build argument is required"; exit 1; fi

# Execute Nx build for the specific project
# Nx automatically resolves internal dependencies (libs/backend/...)
RUN npx nx build ${APP_NAME} --prod

# ------------------------------------------------------------------------------
# STAGE 2: RUNNER (PRODUCTION)
# Description: Minimal runtime image containing only compiled code and prod deps.
# ------------------------------------------------------------------------------
FROM node:20-alpine AS runner

# Set environment to production to optimize Node.js performance
ENV NODE_ENV=production
WORKDIR /app

# Argument: The output path where Nx placed the compiled artifacts
# Example: dist/apps/services/core/auth-service
ARG BUILD_PATH
RUN if [ -z "$BUILD_PATH" ]; then echo "ERROR: BUILD_PATH build argument is required"; exit 1; fi

# Install only production dependencies to keep image size small
# We copy package.json again to ensure runtime dependencies are met
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy the compiled application from the Builder stage
COPY --from=builder /app/${BUILD_PATH} ./dist

# Standard port for NestJS services (can be overridden at runtime)
ENV PORT=3000
EXPOSE 3000

# Start the application
CMD ["node", "dist/main.js"]