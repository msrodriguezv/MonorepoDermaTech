import { Controller, Get, Post, Body, Inject, OnModuleInit, Logger } from '@nestjs/common';
import { ClientKafka, EventPattern, Payload } from '@nestjs/microservices'; // <--- Importar EventPattern
import { PartnerService } from '../services/partner.service';
import { DerivePatientDto } from '../dtos/derive-patient.dto';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('External Referrals')
@Controller() 
export class PartnerController implements OnModuleInit {
  constructor(
    private readonly partnerService: PartnerService,
    @Inject('KAFKA_CLIENT') private readonly kafkaClient: ClientKafka
  ) {}

  async onModuleInit() {
    // Nos suscribimos para escuchar nuestro propio evento y mostrarlo en consola
    this.kafkaClient.subscribeToResponseOf('referral.processed');
    await this.kafkaClient.connect();
  }

  @Get('partners')
  @ApiOperation({ summary: 'List external partners' })
  getPartners() {
    return this.partnerService.getAvailablePartners();
  }

  @Post('derive')
  @ApiOperation({ summary: 'Derive patient' })
  derivePatient(@Body() dto: DerivePatientDto) {
    return this.partnerService.processReferral(dto);
  }

  // 👇 ESTO HARÁ QUE SALGA LA NOTIFICACIÓN EN TU CONSOLA
  @EventPattern('referral.processed')
  async handleReferralNotification(@Payload() data: any) {
    console.log('\n==================================================');
    console.log('🔔 ¡NOTIFICACIÓN KAFKA RECIBIDA! 🔔');
    console.log('==================================================');
    console.log(`🏥 Hospital: ${data.hospitalName}`);
    console.log(`👤 Paciente: ${data.patientId}`);
    console.log(`🔑 Código:   ${data.referralCode}`);
    console.log('==================================================\n');
  }
}