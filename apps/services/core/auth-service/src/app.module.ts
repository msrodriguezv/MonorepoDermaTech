import { Module, Logger } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './infrastructure/auth.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/services/core/auth-service/.env', 
    }),

    // DATABASE CONNECTION
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      // Combined fixes for Safety Logging and Configuration Validation
      useFactory: (configService: ConfigService) => {
        // 1. Safety Check for Synchronization
        const nodeEnv = configService.get<string>('NODE_ENV');
        const synchronize = nodeEnv !== 'production';

        if (synchronize) {
          Logger.warn(
            `    TypeORM synchronize is ENABLED (NODE_ENV="${nodeEnv}"). \n` +
            '    This option should never be enabled against a production database.', 
            'TypeOrmModule'
          );
        }

        // 2. Fetch and Validate Environment Variables
        const host = configService.get<string>('DATABASE_HOST');
        const port = configService.get<number>('DATABASE_PORT');
        const username = configService.get<string>('DATABASE_USER');
        const password = configService.get<string>('DATABASE_PASSWORD');
        const database = configService.get<string>('DATABASE_NAME');

        // If any are missing, we throw a clear and direct error
        if (!host || !port || !username || !password || !database) {
          throw new Error('Database configuration is incomplete. Please check your .env file for HOST, PORT, USER, PASSWORD, and NAME.');
        }

        // 3. Return valid configuration
        return {
          type: 'postgres',
          host,
          port,
          username,
          password,
          database,
          autoLoadEntities: true,
          synchronize,
          ssl: {
            rejectUnauthorized: false,
          },
        };
      },
    }),
    
    AuthModule,
  ],
})
export class AppModule {}