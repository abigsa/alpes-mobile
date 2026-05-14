const { error } = require('../utils/response');

/**
 * Middleware para validar body con esquema Joi
 */
const validarBody = (schema) => {
  return (req, res, next) => {
    const { error: joiError, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true, // Elimina campos no esperados
    });

    if (joiError) {
      const mensajes = joiError.details.map(d => d.message).join(', ');
      console.warn('❌ Validación fallida (body):', mensajes);
      return error(res, mensajes, 400);
    }

    req.body = value;
    next();
  };
};

/**
 * Middleware para validar params con esquema Joi
 */
const validarParams = (schema) => {
  return (req, res, next) => {
    const { error: joiError, value } = schema.validate(req.params, {
      abortEarly: false,
    });

    if (joiError) {
      const mensajes = joiError.details.map(d => d.message).join(', ');
      console.warn('❌ Validación fallida (params):', mensajes);
      return error(res, mensajes, 400);
    }

    req.params = value;
    next();
  };
};

/**
 * Middleware para validar query con esquema Joi
 */
const validarQuery = (schema) => {
  return (req, res, next) => {
    const { error: joiError, value } = schema.validate(req.query, {
      abortEarly: false,
    });

    if (joiError) {
      const mensajes = joiError.details.map(d => d.message).join(', ');
      console.warn('❌ Validación fallida (query):', mensajes);
      return error(res, mensajes, 400);
    }

    req.query = value;
    next();
  };
};

module.exports = { validarBody, validarParams, validarQuery };
