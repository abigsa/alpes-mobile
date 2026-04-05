const jwt = require("jsonwebtoken");
const { JWT_SECRET } = require("../config/jwt.config");
const { error } = require("../utils/response");

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) return error(res, "Token no proporcionado", 401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return error(res, "Token inválido o expirado", 403);
    req.user = user;
    next();
  });
};

const authorizeRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!allowedRoles.includes(req.user.rol)) {
      return error(res, `Acceso denegado. Se requiere rol: ${allowedRoles.join(" o ")}`, 403);
    }
    next();
  };
};

module.exports = { authenticateToken, authorizeRole };

