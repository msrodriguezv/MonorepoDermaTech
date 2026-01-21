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
  // CORRECCIÓN DE RUTAS (PATH REWRITE)
  // Objetivo: Eliminar '/api/v1' antes de enviar al microservicio.
  // Entrada: /api/v1/auth/login  --->  Salida: /auth/login
  // Esto asegura que coincida con @Controller('auth') en el microservicio.
  // ===========================================================================

  // --- AUTH SERVICE ---
  app.use(
    '/api/v1/auth',
    createProxyMiddleware({
      target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3000',
      changeOrigin: true,
      pathRewrite: {
        '^/api/v1/auth': '/auth', // Reemplazamos el prefijo largo por el del controlador
      },
    }),
  );

  // --- PATIENT SERVICE ---
  app.use(
    '/api/v1/patient',
    createProxyMiddleware({
      target: process.env.PATIENT_SERVICE_URL || 'http://patient-service:3000',
      changeOrigin: true,
      pathRewrite: {
        '^/api/v1/patient': '/patient', // Aseguramos que llegue limpio al controlador
      },
    }),
  );

  // --- AI AGENT (Mantenemos tu configuración original si es Python/Flask) ---
  app.use(
    '/api/ai',
    createProxyMiddleware({
      target: process.env.AI_SERVICE_URL || 'http://ai-agent:5000',
      changeOrigin: true,
      pathRewrite: {
        '^/api/ai': '', // Flask suele esperar la raíz '/'
      },
    }),
  );

  const PORT = process.env.PORT || 3000;
  await app.listen(PORT);
  
  logger.log(`🚀 API Gateway running on port ${PORT}`);
}
bootstrap();