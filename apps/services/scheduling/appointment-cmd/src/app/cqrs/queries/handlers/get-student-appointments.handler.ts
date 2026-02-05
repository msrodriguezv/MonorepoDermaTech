import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GetStudentAppointmentsQuery } from '../impl/get-student-appointments.query';
import { Appointment } from '../../../entities/appointment.entity';

@QueryHandler(GetStudentAppointmentsQuery)
export class GetStudentAppointmentsHandler implements IQueryHandler<GetStudentAppointmentsQuery> {
  constructor(
    @InjectRepository(Appointment)
    private readonly appointmentRepo: Repository<Appointment>,
  ) {}

  async execute(query: GetStudentAppointmentsQuery): Promise<Appointment[]> {
    const { studentId } = query;

    return this.appointmentRepo.find({
      where: {
        studentId: studentId,
      },
      relations: ['doctor'], 
      order: {
        startTime: 'DESC',
      },
    });
  }
}