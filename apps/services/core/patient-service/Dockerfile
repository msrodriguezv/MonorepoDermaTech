# ETAPA 1: Construcción (Builder)
FROM node:20-alpine AS builder

# Instalar herramientas necesarias para compilar módulos nativos (si fuera necesario)
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copiar archivos de configuración del Monorepo
COPY package*.json ./
COPY nx.json ./
COPY tsconfig*.json ./

# Instalar todas las dependencias (incluyendo devDependencies para poder compilar)
RUN npm install --legacy-peer-deps

# Copiar todo el código fuente
COPY . .

# Compilar SOLO el patient-service (usamos npx para asegurar que usa el binario local)
RUN npx nx build patient-service --configuration=production

# -----------------------------------------------------------

# ETAPA 2: Ejecución (Runner) - Imagen final liviana
FROM node:20-alpine AS runner
WORKDIR /app

# Crear usuario para seguridad (Requirement: Security)
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

# Copiar solo las dependencias de producción
COPY package*.json ./
RUN npm install --only=production --legacy-peer-deps

# Copiar el compilado desde la etapa anterior
# Nota: Nx deja el compilado en dist/apps/...
COPY --from=builder --chown=nestjs:nodejs /app/dist/apps/services/core/patient-service ./dist

# Configurar entorno
ENV NODE_ENV production
ENV PORT 3001

# Usar el usuario seguro
USER nestjs

# Exponer el puerto
EXPOSE 3001

# Comando de arranque
CMD ["node", "dist/main.js"]