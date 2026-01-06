/* eslint-disable */
export default {
  displayName: 'patient-service',
  preset: '../../../../jest.preset.js',
  testEnvironment: 'node',
  transform: {
    '^.+\\.[tj]s$': ['ts-jest', { 
      tsconfig: '<rootDir>/tsconfig.spec.json',
      diagnostics: false 
    }],
  },
  moduleFileExtensions: ['ts', 'js', 'html'],
  coverageDirectory: '../../../../coverage/apps/services/core/patient-service',
};