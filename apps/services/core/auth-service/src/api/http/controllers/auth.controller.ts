import { Body, Controller, Post, HttpStatus, HttpCode } from '@nestjs/common';
import { CommandBus } from '@nestjs/cqrs';
import { 
  ApiTags, 
  ApiOperation, 
  ApiResponse as SwaggerApiResponse, 
  ApiBadRequestResponse, 
  ApiConflictResponse, 
  ApiUnauthorizedResponse 
} from '@nestjs/swagger';

// Shared Libs (Standardized Response Wrapper)
import { ApiResponse } from '@dermatech/shared-dtos';

// Application & Domain Imports
import { User } from '../../../domain/entities/user.entity';

// --- Register Feature Imports ---
import { RegisterUserCommand } from '../../../application/commands/register-user/register-user.command';
import { RegisterUserDto } from '../dtos/register-user.dto';
import { UserResponseDto } from '../dtos/user-response.dto';

// --- Login Feature Imports ---
import { LoginCommand } from '../../../application/commands/login/login.command';
import { LoginRequestDto } from '../dtos/login.request.dto';
import { TokenResponseDto } from '../dtos/token-response.dto'; // Ensure this file exists as discussed

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly commandBus: CommandBus) {}

  /**
   * Endpoint to register a new user in the system.
   * Emits a domain event to Kafka upon success.
   */
  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register a new user (Student, Doctor, etc.)' })
  @SwaggerApiResponse({ 
    status: 201, 
    description: 'User created successfully.', 
    type: UserResponseDto 
  })
  @ApiBadRequestResponse({ description: 'Validation failed (e.g. invalid email format).' })
  @ApiConflictResponse({ description: 'Email already exists.' })
  async register(@Body() dto: RegisterUserDto): Promise<ApiResponse<UserResponseDto>> {
    
    // 1. Execute Command (CQRS)
    // The CommandHandler returns the Domain Entity (User)
    const user = await this.commandBus.execute<RegisterUserCommand, User>(
      new RegisterUserCommand(dto.email, dto.password, dto.role),
    );

    // 2. Map Domain Entity to Response DTO
    // We explicitly map fields to avoid exposing sensitive data (like password hashes)
    const responseData: UserResponseDto = {
      id: user.getId(),
      email: user.getEmail().email, // Assuming UserEmail VO has a getValue() method
      role: user.getRole(),
      isActive: user.getIsActive(),
    };

    // 3. Return Standardized Response
    return new ApiResponse(
      true,
      'User registered successfully',
      responseData
    );
  }

  /**
   * Endpoint to authenticate a user.
   * Returns JWT Access Token and Refresh Token.
   */
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate user and return JWT tokens' })
  @SwaggerApiResponse({ 
    status: 200, 
    description: 'Login successful.', 
    type: TokenResponseDto 
  })
  @ApiUnauthorizedResponse({ description: 'Invalid credentials or inactive account.' })
  @ApiBadRequestResponse({ description: 'Invalid input data.' })
  async login(@Body() dto: LoginRequestDto): Promise<ApiResponse<TokenResponseDto>> {
    
    // The LoginHandler returns the TokenResponseDto directly (as defined in previous steps)
    const tokens = await this.commandBus.execute<LoginCommand, TokenResponseDto>(
      new LoginCommand(dto.email, dto.password)
    );

    // Return Standardized Response
    return new ApiResponse(
      true,
      'Login successful',
      tokens
    );
  }
}