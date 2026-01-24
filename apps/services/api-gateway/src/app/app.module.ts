import { Module } from '@nestjs/common';

/**
 * Root Module for the API Gateway.
 * * Since this application acts primarily as a Reverse Proxy using 'http-proxy-middleware',
 * we do not need standard Controllers or Services here. The routing logic is 
 * handled in the bootstrap phase (main.ts).
 */
@Module({
  imports: [],
  controllers: [],
  providers: [],
})
export class AppModule {}