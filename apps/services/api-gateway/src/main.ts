import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { createProxyMiddleware } from 'http-proxy-middleware';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('ApiGateway');

  // ===========================================================================
  // 🛡️ CORS CONFIGURATION (Blindado para PROD y QA)
  // ===========================================================================
  const whitelist = [
    'http://localhost:3000',
    'http://localhost:4200',
    'https://martharodriguez_qa1.distribuidauce.org',
    'http://martharodriguez_qa2.distribuidauce.org',
    'http://100.52.22.97',
    'https://martharodriguez_prod1.distribuidauce.org',
    'https://martharodriguez_prod2.distribuidauce.org',
    'http://100.50.124.78'
  ];

  app.enableCors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (whitelist.includes(origin)) {
        callback(null, true);
      } else {
        logger.warn(`⛔ Blocked CORS from: ${origin}`);
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // ===========================================================================
  // 🛣️ SOLUCIÓN DE ENRUTAMIENTO (Sin errores de TypeScript)
  // ===========================================================================

  // --- AUTH SERVICE ---
  app.use(
    '/api/v1/auth',
    createProxyMiddleware({
      // Target limpio: Solo http://host:puerto
      target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3000',
      changeOrigin: true,
      pathRewrite: {
        '^/api/v1/auth': '/auth', // Esto convierte la URL pública en la interna
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
        '^/api/v1/patient': '/patient',
      },
    }),
  );

  // --- AI AGENT ---
  app.use(
    '/api/ai',
    createProxyMiddleware({
      target: process.env.AI_SERVICE_URL || 'http://ai-agent:5000',
      changeOrigin: true,
      pathRewrite: {
        '^/api/ai': '',
      },
    }),
  );

  const PORT = process.env.PORT || 3000;
  await app.listen(PORT);
  
  logger.log(`🚀 API Gateway running on port ${PORT}`);
}
bootstrap();