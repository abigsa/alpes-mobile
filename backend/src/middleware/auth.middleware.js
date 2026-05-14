const jwt = require("jsonwebtoken");
const { JWT_SECRET } = require("../config/jwt.config");
const { error } = require("../utils/response");

/**
 * Verificar y validar JWT
 */
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return error(res, "Token no proporcionado", 401);
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      if (err.name === "TokenExpiredError") {
        return error(res, "Token expirado, usa refresh token", 401);
      }
      return error(res, "Token inválido o expirado", 403);
    }
    
    req.user = user;
    next();
  });
};

/**
 * Verificar rol del usuario (RBAC)
 */
const authorizeRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return error(res, "Usuario no autenticado", 401);
    }

    const userRole = req.user.rol?.toUpperCase();
    const validRoles = allowedRoles.map(r => r.toUpperCase());

    if (!validRoles.includes(userRole)) {
      return error(
        res,
        `Acceso denegado. Se requiere rol: ${allowedRoles.join(" o ")}`,
        403
      );
    }

    next();
  };
};

/**
 * Solo el propietario del recurso o admin
 */
const authorizeOwner = (paramName = "id") => {
  return (req, res, next) => {
    if (!req.user) {
      return error(res, "Usuario no autenticado", 401);
    }

    const resourceId = req.params[paramName];
    const userId = req.user.usuarioId;

    if (resourceId != userId && req.user.rol !== "ADMIN") {
      return error(res, "No tienes permiso para acceder a este recurso", 403);
    }

    next();
  };
};

module.exports = { authenticateToken, authorizeRole, authorizeOwner };
