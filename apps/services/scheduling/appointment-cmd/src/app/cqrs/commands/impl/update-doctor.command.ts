import { UpdateDoctorDto } from '../../../dto/update-doctor.dto';

export class UpdateDoctorCommand {
  constructor(
    public readonly doctorId: string,
    public readonly dto: UpdateDoctorDto,
  ) {}
}