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
  // CORRECCIÓN APLICADA:
  // Se eliminó 'pathRewrite' en Auth y Patient.
  // Ahora el Gateway pasa la URL completa ('/api/v1/auth/...') al microservicio,
  // coincidiendo con el Global Prefix que tienen configurado tus servicios NestJS.
  // ===========================================================================

  // --- AUTH SERVICE ---
  app.use(
    '/api/v1/auth',
    createProxyMiddleware({
      target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3000',
      changeOrigin: true,
    }),
  );

  // --- PATIENT SERVICE ---
  app.use(
    '/api/v1/patient',
    createProxyMiddleware({
      target: process.env.PATIENT_SERVICE_URL || 'http://patient-service:3000',
      changeOrigin: true,
    }),
  );

  // --- AI AGENT ---
  // Mantenemos la reescritura aquí porque Flask/Python usualmente espera la raíz '/'
  app.use(
    '/api/ai',
    createProxyMiddleware({
      target: process.env.AI_SERVICE_URL || 'http://ai-agent:5000',
      changeOrigin: true,
      pathRewrite: {
        '^/api/ai': '', // Flask recibe la ruta limpia desde la raíz
      },
    }),
  );

  const PORT = process.env.PORT || 3000;
  await app.listen(PORT);
  
  logger.log(`🚀 API Gateway FINAL FIX running on port ${PORT}`);
}
bootstrap();