import { Controller, Get } from '@nestjs/common';
import { EventPattern, Payload } from '@nestjs/microservices';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @EventPattern('triage.ingest') 
  async handleStudentIngest(@Payload() message: any) {
    console.log('📨 [NestJS] Nuevo mensaje recibido desde Kafka:');
    console.log(JSON.stringify(message, null, 2));

    // Llamamos al servicio para procesar (Guardar en DB / Llamar IA)
    await this.appService.processTriage(message);
  }
}