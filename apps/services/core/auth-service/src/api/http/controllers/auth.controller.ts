import { Body, Controller, Post, HttpStatus, HttpCode } from '@nestjs/common';
import { CommandBus } from '@nestjs/cqrs';
import { ApiTags, ApiOperation, ApiResponse as SwaggerApiResponse, ApiBadRequestResponse, ApiConflictResponse } from '@nestjs/swagger';

// Shared Libs
import { ApiResponse } from '@dermatech/shared-dtos';

// Application & Domain
import { RegisterUserCommand } from '../../../application/commands/register-user/register-user.command';
import { RegisterUserDto } from '../dtos/register-user.dto';
import { UserResponseDto } from '../dtos/user-response.dto'; // <--- IMPORT THIS
import { User } from '../../../domain/entities/user.entity';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly commandBus: CommandBus) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register a new user (Student, Doctor, etc.)' })
  @SwaggerApiResponse({ status: 201, description: 'User created successfully.', type: UserResponseDto }) // Add type for Swagger
  @ApiBadRequestResponse({ description: 'Validation failed.' })
  @ApiConflictResponse({ description: 'Email already exists.' })
  // CHANGE 1: Return Promise<ApiResponse<UserResponseDto>> instead of Partial<User>
  async register(@Body() dto: RegisterUserDto): Promise<ApiResponse<UserResponseDto>> {
    
    const user = await this.commandBus.execute<RegisterUserCommand, User>(
      new RegisterUserCommand(dto.email, dto.password, dto.role),
    );

    // CHANGE 2: Map the Domain Entity to the Response DTO
    const responseData: UserResponseDto = {
      id: user.getId(),
      email: user.getEmail().email,
      role: user.getRole(),
      isActive: user.getIsActive(),
    };

    return new ApiResponse(
      true,
      'User registered successfully',
      responseData // Now TypeScript is happy because this matches UserResponseDto
    );
  }
}