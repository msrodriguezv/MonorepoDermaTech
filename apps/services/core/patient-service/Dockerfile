FROM node:18-alpine

WORKDIR /app

# 1. Copiamos el package.json desde la ruta QUE TU CONFIRMASTE
# Usamos el comodín *.json por seguridad
COPY dist/apps/services/core/patient-service/package*.json ./

# 2. Instalamos dependencias
RUN npm install --omit=dev

# 3. Copiamos el código compilado (el main.js) desde la misma ruta
COPY dist/apps/services/core/patient-service/main.js ./

EXPOSE 3000

CMD ["node", "main.js"]