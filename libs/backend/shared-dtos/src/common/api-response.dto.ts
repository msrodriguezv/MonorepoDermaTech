import { ApiProperty } from '@nestjs/swagger';

/**
 * Generic wrapper for standardized API responses across all microservices.
 * @template T - The type of the data property.
 */
export class ApiResponse<T> {
  @ApiProperty({
    description: 'Indicates if the operation was successful.',
    example: true,
  })
  success: boolean;

  @ApiProperty({
    description: 'Descriptive message about the operation result.',
    example: 'Operation completed successfully.',
  })
  message: string;

  @ApiProperty({
    description: 'The payload data returned by the endpoint.',
    required: false,
  })
  data?: T;

  @ApiProperty({
    description: 'ISO 8601 timestamp of the response generation.',
    example: '2025-12-31T23:59:59.000Z',
  })
  timestamp: string;

  /**
   * @param success - Operation status.
   * @param message - Human-readable message.
   * @param data - (Optional) Payload data.
   */
  constructor(success: boolean, message: string, data?: T) {
    this.success = success;
    this.message = message;
    this.data = data;
    this.timestamp = new Date().toISOString();
  }
}