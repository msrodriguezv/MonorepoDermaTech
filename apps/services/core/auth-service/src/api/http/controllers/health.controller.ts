import { Controller, Get } from '@nestjs/common';

@Controller('auth/health')
export class HealthController {
  @Get()
  check() {
    return {
      status: 'OK',
      message: 'Auth Service is UP & Running in AWS!',
      environment: process.env.NODE_ENV || 'development',
      timestamp: new Date().toISOString(),
    };
  }
}