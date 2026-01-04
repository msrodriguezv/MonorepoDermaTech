import { Controller, Logger } from '@nestjs/common';
import { EventPattern, Payload } from '@nestjs/microservices';
import { CommandBus } from '@nestjs/cqrs';

// Imports Libs Shared
import { UserRegisteredEvent } from '@dermatech/event-contracts';
import { UserRole } from '@dermatech/shared-dtos';

import { CreatePatientRootCommand } from '../cqrs/commands/impl/create-patient-root.command';

/**
 * PatientEventController
 * * Layer: Presentation (Async/Event Driven).
 * * Responsibility: Consumer of the 'user.registered' Kafka topic.
 */
@Controller()
export class PatientEventController {
  private readonly logger = new Logger(PatientEventController.name);

  constructor(private readonly commandBus: CommandBus) {}

  /**
   * Kafka Event Handler.
   * * Contract: Uses UserRegisteredEvent class to strictly type the incoming payload.
   * * Logic: Based on the shared UserRole enum.
   * * @param event - The deserialized JSON object matching UserRegisteredEvent structure.
   */
  @EventPattern('auth.user.registered')
  async handleUserRegistered(@Payload() event: UserRegisteredEvent) {
    // [DEBUG LOG] Detailed logging to verify payload integrity during development
    this.logger.log(`[Kafka Consumer] Payload received: ${JSON.stringify(event)}`);

    // [VALIDATION] We compare the incoming string 'role' against the strict Enum 'UserRole'.
    // Your Shared Lib defines role as 'string', but matches the Enum values ('STUDENT', etc.)
    if (event.role === UserRole.STUDENT) {
      this.logger.log(`[Logic] Role match verified. Creating patient root for: ${event.email}`);
      
      // Dispatch CQRS Command
      // Properties 'userId' and 'email' are guaranteed by the UserRegisteredEvent contract.
      await this.commandBus.execute(
        new CreatePatientRootCommand(event.userId, event.email),
      );
    } else {
      // Logic for ignoring non-student roles (e.g. ADMIN, DOCTOR) in this specific microservice
      this.logger.debug(`[Logic] Ignored registration for role: ${event.role}`);
    }
  }
}