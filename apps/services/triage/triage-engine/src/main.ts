import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app/app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // CORS habilitado para que no te de problemas si lo llamas desde el front luego
  app.enableCors(); 
  
  const config = new DocumentBuilder()
    .setTitle('Triage Core Service')
    .setDescription('Orquestador de decisiones (Waiting Room vs Emergency)')
    .setVersion('1.0')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);
  
  await app.listen(3006);
  console.log(`🚀 Triage Service running on: http://localhost:3006/api`);
}
bootstrap();