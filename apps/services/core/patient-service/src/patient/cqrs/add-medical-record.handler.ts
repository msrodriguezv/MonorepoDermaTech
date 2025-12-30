import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';

import { AddMedicalRecordCommand } from './add-medical-record.command';
import { Patient } from '../entities/patient.entity';
import { MedicalRecord } from '../entities/medical-record.entity';

@CommandHandler(AddMedicalRecordCommand)
export class AddMedicalRecordHandler implements ICommandHandler<AddMedicalRecordCommand> {
  constructor(
    @InjectRepository(Patient)
    private readonly patientRepository: Repository<Patient>,
    
    @InjectRepository(MedicalRecord) // <--- Inyectamos el repo de la nueva tabla
    private readonly recordRepository: Repository<MedicalRecord>,
  ) {}

  async execute(command: AddMedicalRecordCommand): Promise<MedicalRecord> {
    const { patientId, dto } = command;

    // 1. Verificar que el paciente existe
    const patient = await this.patientRepository.findOne({ where: { id: patientId } });
    if (!patient) {
      throw new NotFoundException(`Patient with ID ${patientId} not found`);
    }

    // 2. Crear el nuevo registro médico
    const newRecord = this.recordRepository.create({
      ...dto,
      patient: patient, // Asignamos la relación
    });

    // 3. Guardar en base de datos
    return await this.recordRepository.save(newRecord);
  }
}