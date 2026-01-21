import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Appointment } from '../../../entities/appointment.entity';
import { GetClinicalQueueQuery } from '../get-clinical-queue.query';

@QueryHandler(GetClinicalQueueQuery)
export class GetClinicalQueueHandler implements IQueryHandler<GetClinicalQueueQuery> {
  constructor(
    @InjectRepository(Appointment)
    private readonly repo: Repository<Appointment>,
  ) {}

  async execute(query: GetClinicalQueueQuery): Promise<Appointment[]> {
    const { status, doctorId } = query;
    
    // Dynamic query construction
    const whereCondition: any = { status };
    
    if (doctorId) {
      whereCondition.doctorId = doctorId;
    }

    return this.repo.find({
      where: whereCondition,
      order: { createdAt: 'ASC' } // FIFO: First In, First Out
    });
  }
}