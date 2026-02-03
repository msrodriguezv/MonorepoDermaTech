import * as crypto from 'crypto';

if (!global.crypto) {
  // @ts-expect-error: Polyfill for Node 18+ compatibility
  global.crypto = crypto;
}
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const logger = new Logger('ExternalPartners');
  
  const app = await NestFactory.create(AppModule);
  
  const configService = app.get(ConfigService);

   // ===========================================================================
  //  SECURITY: PROD CORS CONFIGURATION
  // ===========================================================================
  const whitelist = [
    // --- Local Development ---
    'http://localhost:3000',
    'http://localhost:4200',
    
    // --- QA Environment ---
    'https://martharodriguez_qa1.distribuidauce.org',  // ALB DNS/Domain
    'http://martharodriguez_qa2.distribuidauce.org',   // Static IP Domain (HTTP per env vars)
    'http://100.52.22.97',                             // QA Static IP
    'http://dermatech-qa-alb-868632428.us-east-1.elb.amazonaws.com',

    // --- PROD Environment ---
    'https://martharodriguez_prod1.distribuidauce.org', // ALB DNS/Domain
    'https://martharodriguez_prod2.distribuidauce.org', // Static IP Domain
    'http://100.50.124.78',                             // PROD Static IP
    'http://dermatech-prod-alb-433169419.us-east-1.elb.amazonaws.com'
  ];

  app.enableCors({

    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      
      // Allow requests with no origin (like mobile apps, curl, or server-to-server)
      if (!origin) {
        return callback(null, true);
      }
      
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

  app.setGlobalPrefix('api'); 

  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // 4. Pipes de Validación
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    })
  );

  // 5. Swagger (Documentación)
  const config = new DocumentBuilder()
    .setTitle('External Partners Service') // Título corregido
    .setDescription('Microservicio para gestión de aliados externos')
    .setVersion('1.0')
    .addTag('external-partners')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document); // 👈 Ruta explícita

  // 6. Iniciar Servidor
  const port = configService.get<number>('PORT') || 3004;
  await app.listen(port);
  
  // 7. Logs Dinámicos (Usan el puerto real)
  logger.log(`🚀 External Partners Service running on: http://localhost:${port}/api/v1/`);
  logger.log(`📑 Swagger Docs available at:         http://localhost:${port}/api/docs`);
}
bootstrap();