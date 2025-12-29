import { PartialType } from '@nestjs/swagger';
import { CreatePatientDto } from './create-patient.dto';

// ESTO ES MAGIA:
// 1. Copia firstName, lastName, medicalInfo, avatarUrl, etc.
// 2. Les pone @IsOptional() a todos.
// 3. Mantiene las validaciones estrictas (ej: que medicalInfo respete la estructura interna).
export class UpdatePatientDto extends PartialType(CreatePatientDto) {}