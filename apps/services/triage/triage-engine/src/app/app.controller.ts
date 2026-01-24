import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBody } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('triage')
@Controller('triage')
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Post('analyze')
  @ApiOperation({ summary: 'Analizar síntomas dermatológicos con IA' })
  // Esto obligará a Swagger a mostrar el cuadro de texto con el JSON de ejemplo
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        appointmentId: { type: 'string', example: '01928374-abcd-4f84-b6f5-e3a0dfa95b69' },
        qrData: { type: 'string', example: 'QR-SWAGGER-TEST' },
        symptoms: {
          type: 'object',
          properties: {
            description: { type: 'string', example: 'Tengo manchas rojas en los codos.' },
            painLevel: { type: 'number', example: 5 },
            duration: { type: 'string', example: '3 días' }
          }
        }
      }
    }
  })
  async analyzeSymptoms(@Body() triageData: any) {
    return await this.appService.processTriage(triageData);
  }
}