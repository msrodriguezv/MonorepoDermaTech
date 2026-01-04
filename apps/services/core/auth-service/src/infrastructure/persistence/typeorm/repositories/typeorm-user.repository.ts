import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { UserRepositoryPort } from '../../../../application/ports/user.repository.port';
import { User } from '../../../../domain/entities/user.entity';
import { UserSchema } from '../entities/user.schema';
import { UserMapper } from '../mappers/user.mapper';

/**
 * Persistence Adapter implementing the UserRepositoryPort.
 * Uses TypeORM to interact with the PostgreSQL database.
 */
@Injectable()
export class TypeOrmUserRepository implements UserRepositoryPort {
  
  constructor(
    @InjectRepository(UserSchema)
    private readonly repository: Repository<UserSchema>,
  ) {}

  /**
   * Saves a User domain entity to the database.
   */
  async save(user: User): Promise<User> {
    const persistenceModel = UserMapper.toPersistence(user);
    const savedEntity = await this.repository.save(persistenceModel);
    return UserMapper.toDomain(savedEntity);
  }

  /**
   * Finds a User by email.
   */
  async findByEmail(email: string): Promise<User | null> {
    const foundEntity = await this.repository.findOne({ where: { email } });
    if (!foundEntity) return null;
    return UserMapper.toDomain(foundEntity);
  }

  /**
   * Finds a User by ID.
   */
  async findById(id: string): Promise<User | null> {
    const foundEntity = await this.repository.findOne({ where: { id } });
    if (!foundEntity) return null;
    return UserMapper.toDomain(foundEntity);
  }
}