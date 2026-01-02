import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { Inject, NotFoundException } from '@nestjs/common';
import { GetProfileQuery } from './get-profile.query';
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { UserResponseDto } from '@dermatech/shared-dtos'; 
@QueryHandler(GetProfileQuery)
export class GetProfileHandler implements IQueryHandler<GetProfileQuery> {
  constructor(
    @Inject('UserRepositoryPort')
    private readonly userRepository: UserRepositoryPort,
  ) {}

  async execute(query: GetProfileQuery): Promise<UserResponseDto> {
    const user = await this.userRepository.findById(query.userId);
    if (!user) throw new NotFoundException('User not found');

    return {
      id: user.getId(),
      email: user.getEmail().email,
      role: user.getRole(),
      isActive: user.getIsActive()
    };
  }
}