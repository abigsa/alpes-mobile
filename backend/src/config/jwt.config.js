require("dotenv").config();

module.exports = {
  // JWT Secrets - DEBEN ESTAR EN .env
  JWT_SECRET: process.env.JWT_SECRET || "cambiar_en_produccion_32_caracteres_minimo",
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || "cambiar_en_produccion_32_caracteres_minimo",

  // Token Expiration - IMPORTANTE
  JWT_EXPIRATION: "15m",      // Access token: 15 minutos (CORTO)
  JWT_REFRESH_EXPIRATION: "7d", // Refresh token: 7 días

  // Configuración
  JWT_ALGORITHM: "HS256",
  NODE_ENV: process.env.NODE_ENV || "development",
  IS_PRODUCTION: process.env.NODE_ENV === "production",
};
