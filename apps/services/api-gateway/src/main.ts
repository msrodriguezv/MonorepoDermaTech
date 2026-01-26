import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { createProxyMiddleware, Options } from 'http-proxy-middleware';
import { Logger } from '@nestjs/common';
import { IncomingMessage, ServerResponse, ClientRequest } from 'http';
import { Request, Response } from 'express';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('ApiGateway');

  // ===========================================================================
  // 🛡️ CORS CONFIGURATION
  // ===========================================================================
  const whitelist = [
    'http://localhost:3000',
    'http://localhost:4200',
    'http://localhost:80',
    'https://martharodriguez_qa1.distribuidauce.org', 
    'http://martharodriguez_qa2.distribuidauce.org', 
    'http://100.52.22.97',
    'http://dermatech-qa-alb-868632428.us-east-1.elb.amazonaws.com', 
    'https://martharodriguez_prod1.distribuidauce.org',
    'https://martharodriguez_prod2.distribuidauce.org',
    'http://100.50.124.78',
    /^http:\/\/10\.\d+\.\d+\.\d+/, 
    /^http:\/\/172\.(1[6-9]|2\d|3[01])\.\d+\.\d+/,
  ];

  app.enableCors({
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      if (!origin) return callback(null, true);
      const isAllowed = whitelist.some(allowed => {
        if (typeof allowed === 'string') return allowed === origin;
        return allowed.test(origin);
      });
      if (isAllowed) {
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
  // 🏥 HEALTH CHECK
  // ===========================================================================
  app.use('/api/v1/health', (req: Request, res: Response) => {
    logger.log('Health check pinged');
    res.status(200).json({ status: 'ok', service: 'api-gateway' });
  });

  // ===========================================================================
  // 🛣️ MICROSERVICES ROUTING
  // ===========================================================================

  const handleProxyError = (err: Error, req: IncomingMessage, res: ServerResponse) => {
    logger.error(`Proxy Error: ${err.message}`);
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Service unavailable' }));
  };

  // --- AUTH SERVICE (SIN CAMBIOS) ---
  app.use(
    '/api/v1/auth',
    createProxyMiddleware({
      target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3000',
      changeOrigin: true,
      pathRewrite: (path) => {
        return path.replace(/^\//, '/auth/');
      },
      onError: handleProxyError,
    } as Options), 
  );

  // --- PATIENT SERVICE (CORREGIDO TS ERROR) ---
  app.use(
    '/api/v1/patients', 
    createProxyMiddleware({
      target: process.env.PATIENT_SERVICE_URL || 'http://patient-service:3000',
      changeOrigin: true,
      
      // 1. RECONSTRUCCIÓN DE RUTA (FIX: Quitamos 'req' para calmar a ESLint)
      pathRewrite: (path) => {
        // El 'path' aquí suele llegar cortado. Lo volvemos a armar.
        const finalPath = '/api/v1/patients' + path; 
        return finalPath.replace('//', '/'); 
      },

      // 2. EL CHIVATO (LOGGER)
      // FIX: Quitamos 'res' que no se usaba
      onProxyReq: (proxyReq: ClientRequest, req: IncomingMessage) => {
        logger.log(`[PatientService] ➡️ Proxying ${req.method} to: ${proxyReq.path}`);
      },

      onError: handleProxyError,
    } as Options),
  );

  // --- APPOINTMENT SERVICE ---
  app.use(
    '/api/v1/appointment',
    createProxyMiddleware({
      target: process.env.APPOINTMENT_URL || 'http://appointment-cmd:3000',
      changeOrigin: true,
      pathRewrite: { '^/api/v1/appointment': '/appointment' },
      onError: handleProxyError,
    } as Options),
  );

  // --- AVAILABILITY SERVICE ---
  app.use(
    '/api/v1/availability',
    createProxyMiddleware({
      target: process.env.AVAILABILITY_URL || 'http://availability-qry:3000',
      changeOrigin: true,
      pathRewrite: { '^/api/v1/availability': '/availability' },
      onError: handleProxyError,
    } as Options),
  );

  // --- AI AGENT ---
  app.use(
    '/api/ai',
    createProxyMiddleware({
      target: process.env.AI_SERVICE_URL || 'http://ai-agent:5000',
      changeOrigin: true,
      pathRewrite: { '^/api/ai': '' }, 
      onError: handleProxyError,
    } as Options),
  );

  const PORT = process.env.PORT || 3000;
  await app.listen(PORT, '0.0.0.0');
  logger.log(`🚀 API Gateway running on port ${PORT}`);
}
bootstrap();