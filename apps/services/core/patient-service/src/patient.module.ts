import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CqrsModule } from '@nestjs/cqrs';

// Domain Entities
import { Patient } from './patient/entities/patient.entity';

// Presentation Layer (Controllers)
import { PatientController } from './patient/controllers/patient.controller';
import { PatientEventController } from './patient/controllers/patient-event.controller';

// Domain Services (Business Logic)
import { PatientService } from './patient/services/patient.service';

// CQRS Handlers (Application Layer)
import { CreatePatientRootHandler } from './patient/cqrs/commands/handlers/create-patient-root.handler';
import { UpdateProfileHandler } from './patient/cqrs/commands/handlers/update-profile.handler';
import { GetPatientProfileHandler } from './patient/cqrs/queries/handlers/get-patient-profile.handler';
import { GetAllPatientsHandler } from './patient/cqrs/queries/handlers/get-all-patients.handler';

// Shared Modules Integration
// Importing SharedAuthModule ensures that the Passport Strategies (JWT) are available via Dependency Injection.
import { SharedAuthModule } from '@dermatech/shared-guards'; 

// Grouping Handlers for cleaner module registration
export const CommandHandlers = [
  CreatePatientRootHandler,
  UpdateProfileHandler,
];

export const QueryHandlers = [
  GetPatientProfileHandler,
];

/**
 * PatientModule
 * * The Root Module for the Patient Microservice.
 * * Responsibilities:
 * 1. Registers TypeORM Entities.
 * 2. Configures CQRS Bus.
 * 3. Injects Shared Authentication Modules.
 * 4. Registers Controllers and Providers.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([Patient]), // Register Entity Repository
    CqrsModule,
    SharedAuthModule, // Required for Auth Guards to function correctly
  ],
  controllers: [
    PatientController,
    PatientEventController,
  ],
  providers: [
    // Domain Services
    PatientService,
    // --- QUERY HANDLERS ---
    GetPatientProfileHandler,
    GetAllPatientsHandler,
    // CQRS Handlers
    ...CommandHandlers,
    ...QueryHandlers,
  ],
  exports: [
    PatientService, // Exported for potential inter-module usage (if scaling to Monolith-First)
  ],
})
export class PatientModule {}