const express = require('express');
const router = express.Router();
const autenticacionService = require('../services/autenticacion.service');
const bruteforceService = require('../services/bruteforce.service');
const { ok, error } = require('../utils/response');
const { validarBody } = require('../middleware/validacion.middleware');
const schemas = require('../schemas/validacionSchemas');
const { authenticateToken } = require('../middleware/auth.middleware');

/**
 * POST /api/autenticacion/login
 * Login de usuario - CON VALIDACIÓN, BRUTE FORCE Y MENSAJES DE INTENTOS
 */
router.post('/login', validarBody(schemas.login), async (req, res) => {
  try {
    console.log('🔐 POST /api/autenticacion/login');
    console.log('Body validado:', req.body);

    const { username, contrasena } = req.body;

    // ===== BRUTE FORCE CHECK =====
    const estadoBloqueado = bruteforceService.estasBloqueado(username);
    if (estadoBloqueado.bloqueado) {
      console.warn(`🚫 ${username} está bloqueado por brute force`);
      return error(res, estadoBloqueado.mensaje, 429);
    }

    // ===== INTENTAR LOGIN =====
    try {
      const resultado = await autenticacionService.login(username, contrasena);
      
      // ✅ LOGIN EXITOSO - Limpiar intentos fallidos
      bruteforceService.limpiarIntentos(username);
      console.log(`✅ ${username} login exitoso`);

      return ok(res, resultado, 'Login exitoso', 200);
    } catch (err) {
      // ❌ LOGIN FALLIDO - Registrar intento fallido y obtener info
      const infoIntentos = bruteforceService.registrarIntentoFallido(username);
      console.error(`❌ ${username} login fallido:`, err.message);
      
      // Retornar error CON INFORMACIÓN DE INTENTOS RESTANTES
      return error(
        res,
        {
          mensaje: err.message || 'Credenciales incorrectas',
          bloqueado: infoIntentos.bloqueado,
          intentosRestantes: infoIntentos.intentosRestantes,
          mensajeIntento: infoIntentos.mensaje,
        },
        err.status || 401
      );
    }
  } catch (err) {
    console.error('❌ Error en login:', err);
    return error(res, err.message || 'Error en login', err.status || 500);
  }
});

/**
 * POST /api/autenticacion/registro
 * Registrar nuevo usuario - CON VALIDACIÓN
 */
router.post('/registro', validarBody(schemas.registro), async (req, res) => {
  try {
    console.log('📝 POST /api/autenticacion/registro');
    console.log('Body validado:', req.body);

    const resultado = await autenticacionService.registro(req.body);

    return ok(res, resultado, 'Usuario registrado exitosamente', 201);
  } catch (err) {
    console.error('❌ Error en registro:', err);
    return error(res, err.message || 'Error en registro', err.status || 500);
  }
});

/**
 * POST /api/autenticacion/refresh
 * Refrescar token - CON VALIDACIÓN
 */
router.post('/refresh', validarBody(schemas.refreshToken), async (req, res) => {
  try {
    console.log('🔄 POST /api/autenticacion/refresh');

    const { refreshToken } = req.body;

    const resultado = await autenticacionService.refreshToken(refreshToken);

    return ok(res, resultado, 'Token refrescado', 200);
  } catch (err) {
    console.error('❌ Error en refresh:', err);
    return error(res, err.message || 'Error en refresh', err.status || 500);
  }
});

/**
 * POST /api/autenticacion/logout
 * Logout de usuario - PROTEGIDO
 */
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    console.log('🚪 POST /api/autenticacion/logout');
    console.log('Usuario:', req.user?.usuarioId);

    // En producción, agregar token a blacklist
    return ok(res, { message: 'Logout exitoso' }, 'Sesión cerrada', 200);
  } catch (err) {
    console.error('❌ Error en logout:', err);
    return error(res, err.message || 'Error en logout', 500);
  }
});

/**
 * GET /api/autenticacion/me
 * Obtener perfil del usuario autenticado - PROTEGIDO
 */
router.get('/me', authenticateToken, async (req, res) => {
  try {
    console.log('👤 GET /api/autenticacion/me');
    console.log('Usuario:', req.user?.usuarioId);

    return ok(res, req.user, 'Perfil obtenido');
  } catch (err) {
    console.error('❌ Error obteniendo perfil:', err);
    return error(res, err.message || 'Error obteniendo perfil', 500);
  }
});

module.exports = router;
