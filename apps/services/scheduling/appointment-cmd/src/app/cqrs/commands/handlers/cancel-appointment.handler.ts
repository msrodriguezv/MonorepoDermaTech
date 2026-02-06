// 1. IMPORTAR EventBus
import { CommandHandler, ICommandHandler, EventBus } from '@nestjs/cqrs'; 
import { Logger, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CancelAppointmentCommand } from '../impl/cancel-appointment.command';
import { Appointment, AppointmentStatus } from '../../../entities/appointment.entity';
import { AppointmentCancelledEvent } from '../../events/impl/appointment-cancelled.event'; 

@CommandHandler(CancelAppointmentCommand)
export class CancelAppointmentHandler implements ICommandHandler<CancelAppointmentCommand> {
  private readonly logger = new Logger(CancelAppointmentHandler.name);

  constructor(
    @InjectRepository(Appointment)
    private readonly appointmentRepository: Repository<Appointment>,
    private readonly eventBus: EventBus, 
  ) {}

  async execute(command: CancelAppointmentCommand): Promise<Appointment> {
    const { appointmentId, studentId } = command;

    const appointment = await this.appointmentRepository.findOneBy({ id: appointmentId });

    if (!appointment) {
      throw new NotFoundException(`Appointment with ID ${appointmentId} not found.`);
    }

    if (appointment.studentId !== studentId) {
      throw new ForbiddenException('You are not authorized to cancel this appointment.');
    }

    if (appointment.status === AppointmentStatus.COMPLETED) {
      throw new BadRequestException('Cannot cancel an appointment that has already been completed.');
    }

    if (appointment.status === AppointmentStatus.CANCELLED) {
      return appointment;
    }

    appointment.status = AppointmentStatus.CANCELLED;
    
    const updatedAppointment = await this.appointmentRepository.save(appointment);

    this.logger.log(`🚫 Appointment cancelled: ${updatedAppointment.id} by Student: ${studentId}`);

    this.eventBus.publish(
      new AppointmentCancelledEvent(
        updatedAppointment.id,
        updatedAppointment.doctorId,
        updatedAppointment.startTime 
      )
    );

    return updatedAppointment;
  }
}