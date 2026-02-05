import { CommandHandler, ICommandHandler, EventBus } from '@nestjs/cqrs';
import { Logger, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { BookAppointmentCommand } from '../impl/book-appointment.command';
import { AppointmentCreatedEvent } from '../../events/impl/appointment-created.event';
import { Appointment, AppointmentStatus } from '../../../entities/appointment.entity';
import { Doctor } from '../../../entities/doctor.entity';

@CommandHandler(BookAppointmentCommand)
export class BookAppointmentHandler implements ICommandHandler<BookAppointmentCommand> {
  private readonly logger = new Logger(BookAppointmentHandler.name);
  private readonly APPOINTMENT_DURATION_MINUTES = 30;

  constructor(
    @InjectRepository(Appointment)
    private readonly appointmentRepository: Repository<Appointment>,
    @InjectRepository(Doctor)
    private readonly doctorRepository: Repository<Doctor>,
    private readonly eventBus: EventBus,
  ) {}

  async execute(command: BookAppointmentCommand): Promise<Appointment> {
    const { studentId, dto } = command;
    
    const startTime = new Date(dto.startTime);
    const endTime = new Date(startTime.getTime() + this.APPOINTMENT_DURATION_MINUTES * 60000);

    if (startTime < new Date()) {
      throw new BadRequestException('Cannot book appointments in the past.');
    }

    const doctor = await this.doctorRepository.findOneBy({ id: dto.doctorId });
    if (!doctor) {
      throw new NotFoundException(`Doctor with ID ${dto.doctorId} not found.`);
    }
    if (!doctor.isActive) {
      throw new ConflictException('Doctor is currently not accepting appointments.');
    }

    const overlappingAppointment = await this.appointmentRepository
      .createQueryBuilder('appointment')
      .where('appointment.doctorId = :doctorId', { doctorId: dto.doctorId })
      .andWhere('appointment.status = :status', { status: AppointmentStatus.SCHEDULED })
      .andWhere('appointment.startTime < :endTime', { endTime }) 
      .andWhere('appointment.endTime > :startTime', { startTime }) 
      .getOne();

    if (overlappingAppointment) {
      this.logger.warn(`Overlap detected for Doctor ${dto.doctorId} at ${startTime.toISOString()}`);
      throw new ConflictException('The selected time slot is already booked.');
    }

    const newAppointment = this.appointmentRepository.create({
      doctorId: dto.doctorId,
      studentId: studentId,
      startTime: startTime,
      endTime: endTime,
      status: AppointmentStatus.SCHEDULED,
      symptoms: dto.symptoms, 
    });

    const savedAppointment = await this.appointmentRepository.save(newAppointment);

    this.eventBus.publish(
      new AppointmentCreatedEvent(
        savedAppointment.id,
        savedAppointment.doctorId,
        savedAppointment.studentId,
        savedAppointment.startTime,
        dto.symptoms 
      ),
    );

    this.logger.log(`✅ Appointment booked successfully: ${savedAppointment.id}`);
    
    return savedAppointment;
  }
}