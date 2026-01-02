import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { CryptoServicePort } from '../../application/ports/crypto.service.port';

/**
 * Security Adapter implementing the CryptoServicePort.
 * Uses Bcrypt for secure password hashing.
 * Complies with Mandatory R5 (Security/JWT/Hashing).
 */
@Injectable()
export class BcryptAdapter implements CryptoServicePort {
  private readonly SALT_ROUNDS: number; 

  constructor() {
   //Read from ENV or use 10 by default if it fails
    const envRounds = process.env.BCRYPT_SALT_ROUNDS;
    const parsed = envRounds ? parseInt(envRounds, 10) : NaN;
    this.SALT_ROUNDS = Number.isInteger(parsed) && parsed > 0 ? parsed : 10;
  }

  async hash(plainText: string): Promise<string> {
    return bcrypt.hash(plainText, this.SALT_ROUNDS);
  }

  /**
   * Compares a plain text password with a hash.
   */
  async compare(plainText: string, hash: string): Promise<boolean> {
    return bcrypt.compare(plainText, hash);
  }
}