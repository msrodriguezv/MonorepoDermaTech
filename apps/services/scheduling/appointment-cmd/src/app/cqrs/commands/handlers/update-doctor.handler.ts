import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { UpdateDoctorCommand } from '../impl/update-doctor.command';
import { Doctor } from '../../../entities/doctor.entity';

@CommandHandler(UpdateDoctorCommand)
export class UpdateDoctorHandler implements ICommandHandler<UpdateDoctorCommand> {
  private readonly logger = new Logger(UpdateDoctorHandler.name);

  constructor(
    @InjectRepository(Doctor)
    private readonly doctorRepository: Repository<Doctor>,
  ) {}

  async execute(command: UpdateDoctorCommand): Promise<Doctor> {
    const { doctorId, dto } = command;
    
    const doctor = await this.doctorRepository.findOneBy({ id: doctorId });
    if (!doctor) {
      throw new NotFoundException(`Doctor with ID ${doctorId} not found`);
    }

    this.logger.log(`Updating doctor profile: ${doctorId}`);

    Object.assign(doctor, dto);

    return this.doctorRepository.save(doctor);
  }
}