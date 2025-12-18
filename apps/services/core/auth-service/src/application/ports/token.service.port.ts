import { JwtPayload } from '@dermatech/shared-dtos';

export interface TokenServicePort {
  generateToken(payload: JwtPayload): string;
  verifyToken(token: string): JwtPayload;
}