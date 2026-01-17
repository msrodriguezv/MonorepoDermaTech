import { Controller, Logger } from '@nestjs/common';
import { AppService } from './app.service';
import { EventPattern, Payload } from '@nestjs/microservices';

@Controller()
export class AppController {
  private readonly logger = new Logger(AppController.name);

  constructor(private readonly appService: AppService) {}

  // 📡 ESTA ES LA ANTENA
  @EventPattern('patient-triage-topic') 
  async handlePatientTriage(@Payload() data: any) {
    this.logger.log('📨 ¡Mensaje capturado por NestJS!');
    
    // A veces Kafka envía los datos crudos o dentro de un objeto 'value'.
    // Esta línea asegura que siempre tengamos los datos limpios.
    const pacienteData = data.value ? data.value : data;
    
    await this.appService.processTriage(pacienteData);
  }
}