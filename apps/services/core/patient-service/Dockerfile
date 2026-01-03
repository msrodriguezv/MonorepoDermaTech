# STAGE 1: Builder
# CORRECCIÓN 1: Unificamos a Node 20 (igual que Auth)
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

# CORRECCIÓN 2: Argumento por defecto apunta a patient-service
ARG PROJECT_NAME=patient-service
RUN npx nx build ${PROJECT_NAME} --prod

# STAGE 2: Runner
FROM node:20-alpine

WORKDIR /app

# CORRECCIÓN 3: Copiamos la carpeta correcta (patient-service)
COPY --from=builder /app/dist/apps/services/core/patient-service ./dist
COPY --from=builder /app/node_modules ./node_modules

ENV PORT=${PATIENT_SERVICE_PORT:-${PORT:-3001}}
EXPOSE $PORT

CMD ["node", "dist/main"]