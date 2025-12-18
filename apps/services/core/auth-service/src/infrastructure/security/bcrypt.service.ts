import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { CryptoServicePort } from '../../application/ports/crypto.service.port';

/**
 * Security Adapter implementing the CryptoServicePort.
 * Uses Bcrypt for secure password hashing.
 * Complies with Mandatory R5 (Security/JWT/Hashing).
 */
@Injectable()
export class BcryptService implements CryptoServicePort {
  private readonly SALT_ROUNDS = 10;

  /**
   * Hashes a plain text password.
   */
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