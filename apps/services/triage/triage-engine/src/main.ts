import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  // 1. Crear la aplicación híbrida (HTTP + Microservicio)
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Bootstrap');

  // 2. Configurar la conexión a Kafka
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: {
      client: {
        brokers: ['localhost:9092'], // Tu Kafka local
      },
      consumer: {
        groupId: 'triage-consumer-group', // Identificador del grupo
      },
    },
  });

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

  // 3. Configuración de Swagger corregida
  const config = new DocumentBuilder()
    .setTitle('DermaTech Triage API')
    .setDescription('Sistema de Triaje Dermatológico con Inteligencia Artificial')
    .setVersion('1.0')
    .addTag('triage')
    .addServer('/api') // 👈 ESTO ARREGLA EL ERROR 404 EN SWAGGER
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  
  // Mantenemos la documentación en /api/docs
  SwaggerModule.setup('api/docs', app, document); 

  // 4. Iniciar servicios
  await app.startAllMicroservices(); // Arranca Kafka
  
  const globalPrefix = 'api';
  app.setGlobalPrefix(globalPrefix);
  
  // Usamos el puerto que ya tienes configurado (según tu imagen es el 3007)
  const port = process.env.PORT || 3007; 
  await app.listen(port); 

  Logger.log(
    `🚀 Triage Engine HTTP corriendo en: http://localhost:${port}/${globalPrefix}`
  );
  Logger.log(
    `📖 Documentación Swagger disponible en: http://localhost:${port}/${globalPrefix}/docs`
  );
  Logger.log(`👂 Escuchando eventos de Kafka...`);
}

bootstrap();