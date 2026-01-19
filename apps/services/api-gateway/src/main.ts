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
  // CORRECCIÓN CRÍTICA:
  // 1. Apuntamos a la versión v1 (para coincidir con el Frontend)
  // 2. ELIMINAMOS 'pathRewrite'. El microservicio (Auth) ya tiene configurado
  //    el prefijo global '/api/v1', así que necesita recibir la URL completa.
  // ===========================================================================

  // --- AUTH SERVICE ---
  app.use(
    '/api/v1/auth', // <--- Ajustado para escuchar la versión v1
    createProxyMiddleware({
      target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3000',
      changeOrigin: true,
      // pathRewrite ELIMINADO: Pasamos la ruta tal cual llega
    }),
  );

  // --- PATIENT SERVICE ---
  app.use(
    '/api/v1/patient', // <--- Ajustado para escuchar la versión v1
    createProxyMiddleware({
      target: process.env.PATIENT_SERVICE_URL || 'http://patient-service:3000',
      changeOrigin: true,
      // pathRewrite ELIMINADO
    }),
  );

  // --- AI AGENT ---
  // El AI Agent (Python) suele ser diferente. Si Flask no tiene prefijo /api/ai,
  // aquí SÍ mantenemos el pathRewrite. Depende de tu código Python.
  app.use(
    '/api/ai',
    createProxyMiddleware({
      target: process.env.AI_SERVICE_URL || 'http://ai-agent:5000',
      changeOrigin: true,
      pathRewrite: {
        '^/api/ai': '', // Flask probablemente espera '/' en lugar de '/api/ai'
      },
    }),
  );

  const PORT = process.env.PORT || 3000;
  await app.listen(PORT);
  
  logger.log(`🚀 API Gateway running on port ${PORT}`);
}
bootstrap();