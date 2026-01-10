import { Module } from '@nestjs/common';

// Import the Domain Specific Module
import { AppointmentCmdModule } from './appointment-cmd.module';

/**
 * Root Application Module.
 * Acts as the main entry point and container for the microservice.
 * It imports the feature module where the business logic resides.
 */
@Module({
  imports: [
    // Load the main business logic module
    AppointmentCmdModule,
  ],
  controllers: [], // No default controller
  providers: [],   // No default service
})
export class AppModule {}