import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PartnerController } from './controllers/partner.controller';
import { PartnerService } from './services/partner.service';
import { ReferralLog } from './entities/referral-log.entity';

@Module({
  imports: [
    // 1. Load Environment Variables
    ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env' }),

    // 2. Database Connection
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL, // <--- Now reads the full string from .env
      autoLoadEntities: true,
      synchronize: true, 
      // 👇 SSL LOGIC:
      // If URL contains 'localhost', SSL is OFF.
      // If URL is Supabase (aws-1...), SSL is ON (Required).
      ssl: process.env.DATABASE_URL?.includes('localhost') 
        ? false 
        : { rejectUnauthorized: false },
    }),

    // 3. Register Entity
    TypeOrmModule.forFeature([ReferralLog]),

    // 4. Kafka Client
    ClientsModule.register([
      {
        name: 'KAFKA_CLIENT',
        transport: Transport.KAFKA,
        options: {
          client: {
            clientId: process.env.KAFKA_CLIENT_ID || 'external-partners-svc',
            brokers: [process.env.KAFKA_BROKERS || 'localhost:9092'],
          },
          consumer: {
            groupId: process.env.KAFKA_GROUP_ID || 'external-partners-group',
          },
        },
      },
    ]),
  ],
  controllers: [PartnerController],
  providers: [PartnerService],
})
export class AppModule {}