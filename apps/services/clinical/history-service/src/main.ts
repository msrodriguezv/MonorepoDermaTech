import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Prefijo para diferenciar la API
  const globalPrefix = 'api/clinical';
  app.setGlobalPrefix(globalPrefix);

  // Usamos el puerto 3004
  const port = process.env.PORT || 3004;
  
  await app.listen(port);
  Logger.log(
    `🚀 History Service is running on: http://localhost:${port}/${globalPrefix}`
  );
}

bootstrap();