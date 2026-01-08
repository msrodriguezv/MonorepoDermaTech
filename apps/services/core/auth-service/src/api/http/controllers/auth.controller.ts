import { 
  Controller, 
  Post, 
  Body,
  Headers, 
  UseGuards, 
  HttpStatus, 
  HttpCode 
} from '@nestjs/common';
import { CommandBus } from '@nestjs/cqrs';
import { 
  ApiTags, 
  ApiOperation,
  ApiBearerAuth,
  ApiResponse as SwaggerApiResponse,
  ApiBadRequestResponse, 
  ApiConflictResponse, 
  ApiUnauthorizedResponse
} from '@nestjs/swagger';
import { JwtAuthGuard } from '@dermatech/shared-guards';
import { LogoutCommand } from '../../../application/commands/logout/logout.command';

// Shared Libs (Standardized Response Wrapper)
import { ApiResponse } from '@dermatech/shared-dtos';

// Application & Domain Imports
import { User } from '../../../domain/entities/user.entity';

// --- Register Feature Imports ---
import { RegisterUserCommand } from '../../../application/commands/register-user/register-user.command';
import { RegisterUserDto } from '@dermatech/shared-dtos';
import { UserResponseDto } from '@dermatech/shared-dtos';

// --- Refresh Feature Imports ---
import { RefreshTokenCommand } from '../../../application/commands/refresh-token/refresh-token.command';
import { RefreshTokenDto } from '@dermatech/shared-dtos';

// --- Login Feature Imports ---
import { LoginCommand } from '../../../application/commands/login/login.command';
import { LoginRequestDto } from '@dermatech/shared-dtos';
import { TokenResponseDto } from '@dermatech/shared-dtos';

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
    
    // Execute Command (CQRS)
    const user = await this.commandBus.execute<RegisterUserCommand, User>(
      new RegisterUserCommand(dto.email, dto.password, dto.role),
    );

    // Map Domain Entity to Response DTO
    const responseData: UserResponseDto = {
      id: user.getId(),
      email: user.getEmail().email,
      role: user.getRole(),
      isActive: user.getIsActive(),
    };

    // Return Standardized Response
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
    
    // The LoginHandler returns the TokenResponseDto directly
    const tokens = await this.commandBus.execute<LoginCommand, TokenResponseDto>(
      new LoginCommand(dto.email, dto.password)
    );

    return new ApiResponse(
      true,
      'Login successful',
      tokens
    );
  }

  /**
   * Endpoint to rotate/refresh access tokens.
   * Used when the Access Token expires but the Refresh Token is still valid.
   */
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get a new Access Token using a Refresh Token' })
  @SwaggerApiResponse({ 
    status: 200, 
    description: 'Token refreshed successfully.', 
    type: TokenResponseDto 
  })
  @ApiUnauthorizedResponse({ description: 'Refresh token expired, invalid, or malformed.' })
  async refresh(@Body() dto: RefreshTokenDto): Promise<ApiResponse<TokenResponseDto>> {
    
    // Dispatch Command to validate refresh token and generate new pair
    const tokens = await this.commandBus.execute<RefreshTokenCommand, TokenResponseDto>(
      new RefreshTokenCommand(dto.refreshToken)
    );

    return new ApiResponse(
      true,
      'Token refreshed successfully',
      tokens
    );
  }

  /**
   * Endpoint to invalidate user session.
   * Adds the current token to the Redis Blacklist.
   */
  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Logout user (Invalidate Token via Redis Blacklist)' })
  @SwaggerApiResponse({ status: 200, description: 'Logout successful' })
  @HttpCode(HttpStatus.OK)
  async logout(@Headers('authorization') authHeader: string) {
    // Sanitize the token by removing "Bearer " prefix if present
    const token = authHeader.replace('Bearer ', '').trim();

    // Dispatch the CQRS Command to blacklist the token
    await this.commandBus.execute(
      new LogoutCommand(token)
    );

    return new ApiResponse(true, 'Logout successful');
  }
}