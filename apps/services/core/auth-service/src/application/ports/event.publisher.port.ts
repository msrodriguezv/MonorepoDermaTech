/**
 * Output Port: Defines the contract for publishing domain events.
 * Implemented by the Infrastructure layer (Kafka).
 */
export interface EventPublisherPort {
  /**
   * Publishes an event to a specific topic.
   * @param topic The name of the topic (e.g., 'auth.user_registered')
   * @param event The data object (DTO) to be published
   */
  publish<T>(topic: string, event: T): Promise<void>;
}