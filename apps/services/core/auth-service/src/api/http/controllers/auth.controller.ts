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

// --- Commands & DTOs ---
import { RegisterUserCommand } from '../../../application/commands/register-user/register-user.command';
import { LoginCommand } from '../../../application/commands/login/login.command';
import { RefreshTokenCommand } from '../../../application/commands/refresh-token/refresh-token.command';
import { LogoutCommand } from '../../../application/commands/logout/logout.command';
import { User } from '../../../domain/entities/user.entity';
import { 
  ApiResponse, 
  RegisterUserDto, 
  UserResponseDto, 
  LoginRequestDto, 
  TokenResponseDto, 
  RefreshTokenDto 
} from '@dermatech/shared-dtos';

@ApiTags('auth')
@Controller('auth') // Ruta base interna: /auth
export class AuthController {
  constructor(private readonly commandBus: CommandBus) {}

  // ---------------------------------------------------------------------------
  // REGISTER
  // Ruta final: POST /auth/register
  // ---------------------------------------------------------------------------
  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register a new user' })
  @SwaggerApiResponse({ status: 201, type: UserResponseDto })
  @ApiBadRequestResponse({ description: 'Validation failed' })
  @ApiConflictResponse({ description: 'Email already exists' })
  async register(@Body() dto: RegisterUserDto): Promise<ApiResponse<UserResponseDto>> {
    const user = await this.commandBus.execute<RegisterUserCommand, User>(
      new RegisterUserCommand(dto.email, dto.password, dto.role),
    );

    const responseData: UserResponseDto = {
      id: user.getId(),
      email: user.getEmail().email,
      role: user.getRole(),
      isActive: user.getIsActive(),
    };

    return new ApiResponse(true, 'User registered successfully', responseData);
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // Ruta final: POST /auth/login
  // ---------------------------------------------------------------------------
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate user' })
  @SwaggerApiResponse({ status: 200, type: TokenResponseDto })
  @ApiUnauthorizedResponse({ description: 'Invalid credentials' })
  async login(@Body() dto: LoginRequestDto): Promise<ApiResponse<TokenResponseDto>> {
    const tokens = await this.commandBus.execute<LoginCommand, TokenResponseDto>(
      new LoginCommand(dto.email, dto.password)
    );
    return new ApiResponse(true, 'Login successful', tokens);
  }

  // ---------------------------------------------------------------------------
  // REFRESH TOKEN
  // Ruta final: POST /auth/refresh
  // ---------------------------------------------------------------------------
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh Access Token' })
  @SwaggerApiResponse({ status: 200, type: TokenResponseDto })
  async refresh(@Body() dto: RefreshTokenDto): Promise<ApiResponse<TokenResponseDto>> {
    const tokens = await this.commandBus.execute<RefreshTokenCommand, TokenResponseDto>(
      new RefreshTokenCommand(dto.refreshToken)
    );
    return new ApiResponse(true, 'Token refreshed successfully', tokens);
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // Ruta final: POST /auth/logout
  // ---------------------------------------------------------------------------
  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Logout user' })
  @HttpCode(HttpStatus.OK)
  async logout(@Headers('authorization') authHeader: string) {
    const token = authHeader.replace('Bearer ', '').trim();
    await this.commandBus.execute(new LogoutCommand(token));
    return new ApiResponse(true, 'Logout successful');
  }
}