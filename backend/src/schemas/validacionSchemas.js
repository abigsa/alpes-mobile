const Joi = require('joi');

/**
 * ESQUEMAS DE VALIDACIÓN CON JOI
 * Previenen inyecciones SQL, XSS, y datos malformados
 */

const schemas = {
  // ===== AUTENTICACIÓN =====
  login: Joi.object({
    username: Joi.string()
      .alphanum()
      .min(3)
      .max(50)
      .required()
      .messages({
        'string.base': 'Username debe ser texto',
        'string.alphanum': 'Username solo puede contener letras y números',
        'string.min': 'Username mínimo 3 caracteres',
        'string.max': 'Username máximo 50 caracteres',
        'any.required': 'Username es requerido',
      }),
    contrasena: Joi.string()
      .min(8)
      .max(100)
      .required()
      .messages({
        'string.base': 'Contraseña debe ser texto',
        'string.min': 'Contraseña mínimo 8 caracteres',
        'string.max': 'Contraseña máximo 100 caracteres',
        'any.required': 'Contraseña es requerida',
      }),
  }),

  registro: Joi.object({
    username: Joi.string()
      .alphanum()
      .min(3)
      .max(50)
      .required(),
    email: Joi.string()
      .email()
      .required()
      .messages({
        'string.email': 'Email inválido',
        'any.required': 'Email es requerido',
      }),
    contrasena: Joi.string()
      .min(8)
      .max(100)
      .required()
      .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      .messages({
        'string.min': 'Contraseña mínimo 8 caracteres',
        'string.pattern.base': 'Contraseña debe tener mayúscula, minúscula y número',
      }),
    nombre: Joi.string()
      .max(100)
      .required()
      .messages({
        'any.required': 'Nombre es requerido',
      }),
  }),

  refreshToken: Joi.object({
    refreshToken: Joi.string()
      .required()
      .messages({
        'any.required': 'Refresh token es requerido',
      }),
  }),

  // ===== USUARIOS =====
  actualizarUsuario: Joi.object({
    nombre: Joi.string()
      .max(100)
      .optional(),
    email: Joi.string()
      .email()
      .optional(),
    telefono: Joi.string()
      .pattern(/^[0-9\s\-\+\(\)]+$/)
      .max(20)
      .optional()
      .messages({
        'string.pattern.base': 'Teléfono inválido',
      }),
  }),

  // ===== PRODUCTOS =====
  crearProducto: Joi.object({
    nombre: Joi.string()
      .max(150)
      .required(),
    descripcion: Joi.string()
      .max(1000)
      .optional(),
    precio: Joi.number()
      .positive()
      .required()
      .messages({
        'number.positive': 'Precio debe ser positivo',
      }),
    stock: Joi.number()
      .integer()
      .min(0)
      .required(),
    categoria_id: Joi.number()
      .integer()
      .positive()
      .required(),
  }),

  // ===== CARRITO =====
  agregarCarrito: Joi.object({
    producto_id: Joi.number()
      .integer()
      .positive()
      .required(),
    cantidad: Joi.number()
      .integer()
      .min(1)
      .max(999)
      .required()
      .messages({
        'number.min': 'Cantidad mínimo 1',
        'number.max': 'Cantidad máximo 999',
      }),
  }),

  // ===== PARÁMETROS =====
  idParameter: Joi.object({
    id: Joi.number()
      .integer()
      .positive()
      .required()
      .messages({
        'number.positive': 'ID debe ser un número positivo',
        'any.required': 'ID es requerido',
      }),
  }),

  paginacion: Joi.object({
    page: Joi.number()
      .integer()
      .min(1)
      .optional()
      .default(1),
    limit: Joi.number()
      .integer()
      .min(1)
      .max(100)
      .optional()
      .default(10),
  }),
};

module.exports = schemas;
