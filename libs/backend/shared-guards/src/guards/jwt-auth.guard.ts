import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Standard JWT Guard.
 * Apply this guard to any Controller or Endpoint that requires authentication.
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}