import { AddMedicalRecordDto } from '../dto/add-medical-record.dto';

export class AddMedicalRecordCommand {
  constructor(
    public readonly patientId: string,
    public readonly dto: AddMedicalRecordDto,
  ) {}
}