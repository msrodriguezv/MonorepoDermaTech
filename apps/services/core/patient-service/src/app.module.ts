import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PatientModule } from './patient/patient.module';
import { Patient } from './patient/entities/patient.entity';
import { JwtStrategy } from './common/strategies/jwt.strategy';

@Module({
  imports: [
    // 1. Configuración Global (Lee archivo .env)
    ConfigModule.forRoot({
      isGlobal: true,
    }),

    // 2. Conexión a Base de Datos (Postgres)
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST'),
        port: parseInt(config.get<string>('DB_PORT') || '5432'),
        username: config.get<string>('DB_USER'),
        password: config.get<string>('DB_PASS'),
        database: config.get<string>('DB_NAME'),
        entities: [Patient], // Registramos la entidad
        synchronize: true, // ¡OJO! True solo en desarrollo/tesis. En prod es false.
        autoLoadEntities: true,
      }),
      inject: [ConfigService],
    }),

    // 3. Importamos nuestro módulo de negocio
    PatientModule,
  ],
  controllers: [],
  // 4. Registramos la estrategia de seguridad globalmente
  providers: [JwtStrategy],
})
export class AppModule {}