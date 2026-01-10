import { CommandHandler, ICommandHandler, EventBus } from '@nestjs/cqrs';
import { Logger, NotFoundException, ConflictException, InternalServerErrorException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan, MoreThan } from 'typeorm';

import { BookAppointmentCommand } from '../impl/book-appointment.command';
import { AppointmentCreatedEvent } from '../../events/impl/appointment-created.event';
import { Appointment, AppointmentStatus } from '../../../entities/appointment.entity';
import { Doctor } from '../../../entities/doctor.entity';

@CommandHandler(BookAppointmentCommand)
export class BookAppointmentHandler implements ICommandHandler<BookAppointmentCommand> {
  private readonly logger = new Logger(BookAppointmentHandler.name);

  constructor(
    @InjectRepository(Appointment)
    private readonly appointmentRepository: Repository<Appointment>,
    @InjectRepository(Doctor)
    private readonly doctorRepository: Repository<Doctor>,
    private readonly eventBus: EventBus, // Event-Driven Backbone
  ) {}

  /**
   * Executes the booking logic.
   * 1. Validate Doctor existence.
   * 2. Validate Time Logic (Start < End).
   * 3. Check for Overlaps (Concurrency Check).
   * 4. Persist.
   * 5. Publish Event.
   */
  async execute(command: BookAppointmentCommand): Promise<Appointment> {
    const { studentId, dto } = command;
    const startTime = new Date(dto.startTime);
    const endTime = new Date(dto.endTime);

    this.logger.log(`[Booking] Request: Student ${studentId} with Doctor ${dto.doctorId}`);

    // 1. Basic Logic Validation
    if (startTime >= endTime) {
      throw new BadRequestException('Start time must be before end time.');
    }

    try {
      // 2. Validate Doctor
      const doctor = await this.doctorRepository.findOneBy({ id: dto.doctorId });
      if (!doctor) {
        throw new NotFoundException(`Doctor with ID ${dto.doctorId} not found.`);
      }
      if (!doctor.isActive) {
        throw new ConflictException('Doctor is currently not accepting appointments.');
      }

      // 3. CRITICAL: Overlap Check (Prevent Double Booking)
      // Logic: An existing appointment overlaps if it Starts BEFORE my End AND Ends AFTER my Start.
      const conflictingAppointment = await this.appointmentRepository.findOne({
        where: {
          doctorId: dto.doctorId,
          status: AppointmentStatus.SCHEDULED, // Only check active appointments
          startTime: LessThan(endTime),
          endTime: MoreThan(startTime),
        },
      });

      if (conflictingAppointment) {
        this.logger.warn(`[Booking] Conflict detected for Doctor ${dto.doctorId} at ${startTime}`);
        throw new ConflictException('The selected time slot is already booked.');
      }

      // 4. Create & Persist
      const appointment = this.appointmentRepository.create({
        doctorId: dto.doctorId,
        studentId: studentId,
        startTime: startTime,
        endTime: endTime,
        status: AppointmentStatus.SCHEDULED,
      });

      const savedAppointment = await this.appointmentRepository.save(appointment);

      // 5. Publish Domain Event (Fire & Forget)
      // This triggers Kafka/Notifications asynchronously
      this.eventBus.publish(
        new AppointmentCreatedEvent(
          savedAppointment.id,
          savedAppointment.doctorId,
          savedAppointment.studentId,
          savedAppointment.startTime,
        ),
      );

      this.logger.log(`✅ Appointment booked: ${savedAppointment.id}`);
      return savedAppointment;

    } catch (error) {
      // Re-throw expected HTTP exceptions
      if (error instanceof NotFoundException || error instanceof ConflictException || error instanceof BadRequestException) {
        throw error;
      }
      
      this.logger.error(`[Booking] System Error: ${error.message}`, error.stack);
      throw new InternalServerErrorException('An unexpected error occurred while booking the appointment.');
    }
  }
}