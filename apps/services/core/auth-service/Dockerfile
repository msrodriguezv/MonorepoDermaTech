# apps/services/core/auth-service/Dockerfile

# Usamos una imagen ligera de Node
FROM node:18-alpine

WORKDIR /app

# 1. Copiamos el package.json GENERADO por Nx (no el de la raíz)
# Nx genera un package.json en el dist que tiene SOLO lo necesario para correr
COPY dist/apps/services/core/auth-service/package*.json ./

# 2. Instalamos dependencias de producción
# (Las librerías shared YA están compiladas en el JS, esto es solo para librerías de terceros como 'nestjs', 'reflect-metadata', etc.)
RUN npm install --omit=dev

# 3. Copiamos el main.js que YA TIENE tus shared-dtos integrados
COPY dist/apps/services/core/auth-service/main.js ./

# 4. Exponer puerto y correr
EXPOSE 3000
CMD ["node", "main.js"]