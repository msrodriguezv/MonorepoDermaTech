import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GetAllDoctorsQuery } from '../impl/get-all-doctors.query';
import { Doctor } from '../../../entities/doctor.entity';

@QueryHandler(GetAllDoctorsQuery)
export class GetAllDoctorsHandler implements IQueryHandler<GetAllDoctorsQuery> {
  constructor(
    @InjectRepository(Doctor)
    private readonly doctorRepository: Repository<Doctor>,
  ) {}

  async execute(query: GetAllDoctorsQuery): Promise<Doctor[]> {
    if (query.includeInactive) {
      return this.doctorRepository.find({
        order: { lastName: 'ASC' },
      });
    }

    return this.doctorRepository.find({
      where: { isActive: true },
      order: { lastName: 'ASC' },
    });
  }
}