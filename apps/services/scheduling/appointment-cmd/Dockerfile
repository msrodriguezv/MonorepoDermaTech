# STEP 1: Multi-stage build for production optimization
FROM node:18-slim

RUN apt-get update && apt-get install -y dumb-init

# Set production environments
ENV NODE_ENV=production
WORKDIR /app

# Copy root package files for dependency installation
COPY package*.json ./

# Install ONLY production dependencies to keep the image slim
RUN npm ci --only=production --ignore-scripts && npm cache clean --force

# Copy the pre-compiled code from the Nx 'dist' folder
# The build is performed in the CI/CD pipeline, not inside Docker
ARG SERVICE_PATH
COPY dist/apps/services/${SERVICE_PATH} ./dist

# Use a non-privileged user for security compliance
USER node

# Standard NestJS port
EXPOSE 3000

# Execution using dumb-init as entrypoint
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "dist/main.js"]