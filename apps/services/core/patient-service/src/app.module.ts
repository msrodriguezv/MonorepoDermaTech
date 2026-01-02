import { Module,Logger } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PatientModule } from './patient/patient.module'; 

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const host = configService.get('DB_HOST');
        const port = configService.get('DB_PORT');
        Logger.log('--- CONNECTION ATTEMPT ---', 'AppModule');
        Logger.log(`HOST: ${host}`, 'AppModule');
        Logger.log(`PORT: ${port}`, 'AppModule');
        Logger.log('---------------------------', 'AppModule');
        return {
         type: 'postgres',
          host: host,
          port: port,
          username: configService.get<string>('DB_USER'),
          password: configService.get<string>('DB_PASSWORD'),
          database: configService.get<string>('DB_NAME'),
          autoLoadEntities: true,
          synchronize: configService.get<string>('NODE_ENV') !== 'production',
          ssl: {
            rejectUnauthorized: false, 
          },
        };
      },
    }),
    PatientModule, 
  ],
})
export class AppModule {}