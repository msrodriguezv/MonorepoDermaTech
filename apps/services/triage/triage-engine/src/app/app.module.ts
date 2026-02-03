import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';

import { TriageController } from './controllers/triage.controller';
import { TriageService } from './services/triage.service';
import { TriageRecord } from './entities/triage-record.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    HttpModule, // Para llamar a Python y Go
    
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get<string>('DB_USER'),
        password: config.get<string>('DB_PASSWORD'),
        database: config.get<string>('DB_NAME'),
        entities: [TriageRecord],
        autoLoadEntities: true,
        synchronize: false, 
      }),
    }),
    TypeOrmModule.forFeature([TriageRecord]),
  ],
  controllers: [TriageController],
  providers: [TriageService],
})
export class AppModule {}