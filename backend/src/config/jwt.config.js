require("dotenv").config();

module.exports = {
  // JWT Secrets
  JWT_SECRET: process.env.JWT_SECRET || "tu_super_secreto_jwt_development_change_in_production",
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || "tu_super_secreto_refresh_development_change_in_production",

  // Token Expiration
  JWT_EXPIRATION: "15m",      // Access token: 15 minutos
  JWT_REFRESH_EXPIRATION: "7d", // Refresh token: 7 días

  // Ambiente
  NODE_ENV: process.env.NODE_ENV || "development",
  IS_PRODUCTION: process.env.NODE_ENV === "production",
};
