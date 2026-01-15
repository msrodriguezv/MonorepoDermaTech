import { Injectable, Logger, Inject, NotFoundException } from '@nestjs/common';
import { ClientKafka } from '@nestjs/microservices';
import { InjectRepository } from '@nestjs/typeorm'; 
import { Repository } from 'typeorm';               
import { DerivePatientDto } from '../dtos/derive-patient.dto';
import { ReferralLog } from '../entities/referral-log.entity';

@Injectable()
export class PartnerService {
  private readonly logger = new Logger(PartnerService.name);

  private readonly contactList = [
    { id: 'HOSPITAL-METRO', name: 'Metropolitan Hospital', specialty: 'General' },
    { id: 'CLINICA-SG', name: 'San Gabriel Clinic', specialty: 'Traumatology' },
    { id: 'HOSPITAL-PC', name: 'Padre Carolo Hospital', specialty: 'General' },
  ];

  constructor(
    @Inject('KAFKA_CLIENT') private readonly kafkaClient: ClientKafka,
    
    
    @InjectRepository(ReferralLog)
    private readonly referralRepo: Repository<ReferralLog>,
  ) {}

  getAvailablePartners() {
    return this.contactList;
  }

  async processReferral(data: DerivePatientDto) {
    this.logger.log(`🔄 Procesando derivación para paciente: ${data.patientId}`);

    
    const hospital = this.contactList.find(h => h.id === data.targetHospitalId);
    if (!hospital) {
      throw new NotFoundException(`Hospital ID ${data.targetHospitalId} not found.`);
    }

    
    await new Promise(resolve => setTimeout(resolve, 1000));

    
    const authCode = `AUT-${Math.floor(Math.random() * 100000)}`;

    
    const newReferral = this.referralRepo.create({
      patientId: data.patientId,
      doctorId: data.doctorId,
      hospitalId: hospital.id,
      hospitalName: hospital.name,
      reason: data.reason,
      referralCode: authCode,
    });
    
    const savedRecord = await this.referralRepo.save(newReferral);
    this.logger.log(`💾 Guardado en Base de Datos (ID: ${savedRecord.id})`);

    
    const eventPayload = {
      ...savedRecord, 
      eventType: 'REFERRAL_CREATED',
    };

    this.kafkaClient.emit('referral.processed', eventPayload);

    return {
      success: true,
      message: 'Referral processed successfully.',
      data: {
        hospital: hospital.name,
        authorizationCode: authCode,
        trackingId: savedRecord.id
      }
    };
  }
}