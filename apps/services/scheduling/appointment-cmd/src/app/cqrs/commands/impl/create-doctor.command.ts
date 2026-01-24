import { CreateDoctorDto } from '../../../dto/create-doctor.dto';

/**
 * Command representing the intent to create a Doctor.
 * Carries the validated data payload to the Write Model.
 */
export class CreateDoctorCommand {
  constructor(public readonly dto: CreateDoctorDto) {}
}