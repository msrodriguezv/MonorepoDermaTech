import { Module, Logger } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { join } from 'path';

@Module({
  imports: [
    // 1. Configuración de Variables de Entorno (Con ruta absoluta y depuración)
    ConfigModule.forRoot({
      isGlobal: true,
      // Usamos join y process.cwd() para asegurar que encuentre el archivo en Windows
      envFilePath: join(process.cwd(), 'apps/services/clinical/history-service/.env'),
    }),

    // 2. Conexión Asíncrona con Logs
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => {
        const uri = configService.get<string>('MONGO_URI');
        const logger = new Logger('MongooseConnection');
        
        // 🔍 DEBUG: Imprimimos qué está intentando leer
        logger.warn(`Intentando conectar a Mongo...`);
        logger.log(`Ruta del .env buscada: ${join(process.cwd(), 'apps/services/clinical/history-service/.env')}`);
        
        if (!uri) {
          logger.error('❌ ERROR CRÍTICO: La variable MONGO_URI es undefined. Revisa el archivo .env');
        } else {
          logger.log('✅ Variable MONGO_URI encontrada (oculta por seguridad)');
        }

        return {
          uri: uri,
        };
      },
      inject: [ConfigService],
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}