import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TriageRecord } from './entities/triage-record.entity';
import { AppService } from './app/app.service';      
import { TriageController } from './controllers/triage.controller';
import { AppController } from './app/app.controller';
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/services/triage/triage-engine/.env',
    }),

    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      synchronize: true,
      autoLoadEntities: true,
      ssl: {
        rejectUnauthorized: false, 
      },
    }),

    TypeOrmModule.forFeature([TriageRecord]),
  ],
  
  controllers: [AppController, TriageController], 
  
  providers: [AppService], 
})
export class AppModule {}