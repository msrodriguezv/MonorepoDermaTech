const { composePlugins, withNx } = require('@nx/webpack');

// Configuración universal para NestJS en Nx
module.exports = composePlugins(withNx(), (config) => {
  // Aquí puedes personalizar Webpack si lo necesitas en el futuro
  return config;
});