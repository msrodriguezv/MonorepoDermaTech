import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { createProxyMiddleware } from 'http-proxy-middleware';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('ApiGateway');

  app.enableCors({
    origin: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // ===========================================================================
  // SOLUCIÓN PROFESIONAL (TARGET BASE PATH):
  // Usamos 'app.use' para el enrutamiento (lo que satisface a TypeScript).
  // Express cortará el prefijo, PERO lo incluimos en el 'target'.
  // La librería unirá automáticamente: Target Base + Ruta Cortada.
  // ===========================================================================

  // --- AUTH SERVICE ---
  // Entrada: /api/v1/auth/login  -> Express deja: /login
  // Target: .../api/v1/auth      -> Proxy une: .../api/v1/auth/login
  app.use(
    '/api/v1/auth',
    createProxyMiddleware({
      // AQUI ESTA LA CLAVE: Incluimos la ruta base en el target
      target: process.env.AUTH_SERVICE_URL 
        ? `${process.env.AUTH_SERVICE_URL}/api/v1/auth` 
        : 'http://auth-service:3000/api/v1/auth',
      changeOrigin: true,
    }),
  );

  // --- PATIENT SERVICE ---
  // Misma lógica limpia.
  app.use(
    '/api/v1/patient',
    createProxyMiddleware({
      target: process.env.PATIENT_SERVICE_URL 
        ? `${process.env.PATIENT_SERVICE_URL}/api/v1/patient` 
        : 'http://patient-service:3000/api/v1/patient',
      changeOrigin: true,
    }),
  );

  // --- AI AGENT ---
  // Este es diferente. Flask espera la raíz '/'.
  // Express corta '/api/ai' y deja '/'.
  // El target es la raíz. Matemáticamente encaja perfecto sin cambios.
  app.use(
    '/api/ai',
    createProxyMiddleware({
      target: process.env.AI_SERVICE_URL || 'http://ai-agent:5000',
      changeOrigin: true,
    }),
  );

  const PORT = process.env.PORT || 3000;
  await app.listen(PORT);
  
  logger.log(`🚀 API Gateway CLEAN-TARGET running on port ${PORT}`);
}
bootstrap();