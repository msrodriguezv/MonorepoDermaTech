import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';

import { Appointment, AppointmentStatus } from '../../../entities/appointment.entity';
import { TriagePatientCommand } from '../impl/triage-patient.command';
import { TriageOutcome } from '../../../dto/triage-decision.dto';

/**
 * Handles the business logic for the Triage process.
 * Updates the appointment status based on the nurse's evaluation.
 */
@CommandHandler(TriagePatientCommand)
export class TriagePatientHandler implements ICommandHandler<TriagePatientCommand> {
  constructor(
    @InjectRepository(Appointment)
    private readonly repo: Repository<Appointment>,
  ) {}

  async execute(command: TriagePatientCommand): Promise<Appointment> {
    const { appointmentId, dto } = command;
    
    // 1. Find the appointment
    const appointment = await this.repo.findOneBy({ id: appointmentId });
    if (!appointment) throw new NotFoundException('Cita no encontrada');

    // 2. Apply State Transition Logic
    if (dto.outcome === TriageOutcome.PASS_TO_DOCTOR) {
      appointment.status = AppointmentStatus.WAITING_FOR_DOCTOR;
    } else {
      appointment.status = AppointmentStatus.REFERRED;
    }

    // 3. Save Nurse Notes
    appointment.nurseNotes = dto.notes;

    // 4. Persist changes
    return this.repo.save(appointment);
  }
}