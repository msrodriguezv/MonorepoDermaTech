import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { CreatePatientCommand } from './create-patient.command';
import { PatientService } from '../services/patient.service';

@CommandHandler(CreatePatientCommand)
export class CreatePatientHandler implements ICommandHandler<CreatePatientCommand> {
  // Inyectamos el servicio para reutilizar la lógica que ya escribiste
  // (Esta es la forma más segura de hacerlo sin romper tus tests anteriores)
  constructor(private readonly patientService: PatientService) {}

  async execute(command: CreatePatientCommand) {
    const { createPatientDto } = command;
    // Delegamos la tarea al servicio (Reutilización)
    return await this.patientService.create(createPatientDto);
  }
}