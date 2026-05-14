const express = require('express');
const router = express.Router();
const notificacionService = require('../services/notificacion.service');
const { ok, error } = require('../utils/response');
const { authenticateToken } = require('../middleware/auth.middleware');

/**
 * GET /api/notificaciones/no-leidas
 * Obtener notificaciones no leídas para el admin
 * ✅ PROTEGIDO
 */
router.get('/no-leidas', authenticateToken, async (req, res) => {
  try {
    console.log(`📬 GET /api/notificaciones/no-leidas - Usuario: ${req.user?.rol}`);

    const rolNombre = req.user?.rol || 'CLIENTE';
    const notificaciones = notificacionService.obtenerNotificacionesNoLeidas(rolNombre);
    const cantidad = notificaciones.length;

    return ok(res, {
      cantidad: cantidad,
      notificaciones: notificaciones,
    }, `${cantidad} notificaciones no leídas`);
  } catch (err) {
    console.error('❌ Error obteniendo notificaciones:', err);
    return error(res, err.message || 'Error obteniendo notificaciones', 500);
  }
});

/**
 * GET /api/notificaciones
 * Obtener todas las notificaciones (últimas 50)
 * ✅ PROTEGIDO
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    console.log(`📬 GET /api/notificaciones - Usuario: ${req.user?.rol}`);

    const rolNombre = req.user?.rol || 'CLIENTE';
    const notificaciones = notificacionService.obtenerTodasNotificaciones(rolNombre, 50);

    return ok(res, {
      cantidad: notificaciones.length,
      notificaciones: notificaciones,
    }, 'Notificaciones obtenidas');
  } catch (err) {
    console.error('❌ Error obteniendo notificaciones:', err);
    return error(res, err.message || 'Error obteniendo notificaciones', 500);
  }
});

/**
 * GET /api/notificaciones/conteo
 * Obtener conteo de notificaciones no leídas
 * ✅ PROTEGIDO
 */
router.get('/conteo/no-leidas', authenticateToken, async (req, res) => {
  try {
    const rolNombre = req.user?.rol || 'CLIENTE';
    const cantidad = notificacionService.obtenerConteoNoLeidas(rolNombre);

    return ok(res, {
      cantidad: cantidad,
    }, `${cantidad} notificaciones no leídas`);
  } catch (err) {
    console.error('❌ Error obteniendo conteo:', err);
    return error(res, err.message || 'Error obteniendo conteo', 500);
  }
});

/**
 * PUT /api/notificaciones/:id/leer
 * Marcar notificación como leída
 * ✅ PROTEGIDO
 */
router.put('/:id/leer', authenticateToken, async (req, res) => {
  try {
    const notificacionId = parseInt(req.params.id);
    const resultado = notificacionService.marcarComoLeida(notificacionId);

    if (!resultado) {
      return error(res, 'Notificación no encontrada', 404);
    }

    return ok(res, null, 'Notificación marcada como leída');
  } catch (err) {
    console.error('❌ Error marcando notificación:', err);
    return error(res, err.message || 'Error marcando notificación', 500);
  }
});

/**
 * PUT /api/notificaciones/leer-todas
 * Marcar todas las notificaciones como leídas
 * ✅ PROTEGIDO
 */
router.put('/leer-todas', authenticateToken, async (req, res) => {
  try {
    const rolNombre = req.user?.rol || 'CLIENTE';
    const cantidad = notificacionService.marcarTodasComoLeidas(rolNombre);

    return ok(res, { cantidad: cantidad }, `${cantidad} notificaciones marcadas como leídas`);
  } catch (err) {
    console.error('❌ Error marcando notificaciones:', err);
    return error(res, err.message || 'Error marcando notificaciones', 500);
  }
});

module.exports = router;
