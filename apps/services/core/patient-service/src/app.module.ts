import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PatientsModule } from './patient/patient.module'; 

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const host = configService.get('DB_HOST');
        const port = configService.get('DB_PORT');

        console.log(`--- INTENTO DE CONEXIÓN ---`);
        console.log(`HOST: ${host}`);
        console.log(`PUERTO: ${port}`);
        console.log(`---------------------------`);

        return {
          type: 'postgres',
          host: host,
          port: parseInt(port, 10), 
          username: configService.get('DB_USER'),
          password: configService.get('DB_PASSWORD'),
          database: configService.get('DB_NAME'),
          autoLoadEntities: true,
          synchronize: true,
          
          ssl: {
            rejectUnauthorized: false, 
          },
        };
      },
    }),
    PatientsModule, 
  ],
})
export class AppModule {}