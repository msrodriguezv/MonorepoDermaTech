import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'; // <--- 1. Importar esto
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    // 2. Configurar el ConfigModule 
    ConfigModule.forRoot({
      isGlobal: true, // Hace que ConfigService esté disponible en toda la app
      // Asegúrate de que esta ruta apunte a tu archivo .env
      envFilePath: 'apps/services/support/external-partners/.env', 
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}