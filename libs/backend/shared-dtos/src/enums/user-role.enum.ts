/**
 * Defines the standard roles within the DermaTech ecosystem.
 * Used for RBAC (Role-Based Access Control) across microservices.
 */
export enum UserRole {
  STUDENT = 'STUDENT', // Patient context
  DOCTOR = 'DOCTOR',   // Medical context
  NURSE = 'NURSE',     // Triage context
  ADMIN = 'ADMIN',     // Management context
}