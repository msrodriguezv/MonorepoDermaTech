import { Test, TestingModule } from '@nestjs/testing';
import { ClientKafka } from '@nestjs/microservices';
import { KafkaEventPublisher } from './kafka-event.publisher';
import { of } from 'rxjs';

describe('KafkaEventPublisher', () => {
  let publisher: KafkaEventPublisher;
  let kafkaClientMock: ClientKafka;

  beforeEach(async () => {
    // Create a Mock for the ClientKafka dependency
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        KafkaEventPublisher,
        {
          provide: 'AUTH_KAFKA_CLIENT', // Must match the Injection Token
          useValue: {
            connect: jest.fn(),
            emit: jest.fn(() => of('success')), // Mock emit returning an Observable
          },
        },
      ],
    }).compile();

    publisher = module.get<KafkaEventPublisher>(KafkaEventPublisher);
    kafkaClientMock = module.get<ClientKafka>('AUTH_KAFKA_CLIENT');
  });

  it('should be defined', () => {
    expect(publisher).toBeDefined();
  });

  it('should connect to Kafka on module init', async () => {
    // Act
    await publisher.onModuleInit();
    // Assert
    expect(kafkaClientMock.connect).toHaveBeenCalled();
  });

  it('should emit a message to the correct topic', async () => {
    // Arrange
    const topic = 'user.registered';
    const payload = { userId: '123', email: 'test@test.com' };

    // Act
    await publisher.publish(topic, payload);

    // Assert
    // Verify that the underlying Kafka client was called with expected arguments
    expect(kafkaClientMock.emit).toHaveBeenCalledWith(topic, payload);
  });
});