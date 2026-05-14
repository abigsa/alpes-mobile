/**
 * SERVICIO DE NOTIFICACIONES
 * Envía notificaciones a admins cuando:
 * - Se crea una nueva orden
 * - Se actualiza estado de orden
 * - Se recibe un pago
 */

// En memoria (en producción usar base de datos + WebSocket)
const notificaciones = new Map();
let notificacionId = 1;

/**
 * Crear notificación para admins
 */
function crearNotificacionOrden(datos) {
  const notif = {
    id: notificacionId++,
    tipo: 'NUEVA_ORDEN',
    titulo: `Nueva orden #${datos.orden_id}`,
    descripcion: `Orden creada por ${datos.cliente_nombre || 'Cliente'} - $${datos.monto || 0}`,
    orden_id: datos.orden_id,
    cliente_id: datos.cliente_id,
    monto: datos.monto,
    timestamp: new Date(),
    leida: false,
    para_roles: ['ADMINISTRADOR', 'GERENTE'],
  };

  notificaciones.set(notif.id, notif);
  console.log(`📢 Notificación creada: ${notif.titulo}`);
  
  return notif;
}

/**
 * Crear notificación de cambio de estado
 */
function crearNotificacionEstado(datos) {
  const notif = {
    id: notificacionId++,
    tipo: 'CAMBIO_ESTADO_ORDEN',
    titulo: `Orden #${datos.orden_id} cambió a ${datos.estado_nuevo}`,
    descripcion: `Estado: ${datos.estado_anterior} → ${datos.estado_nuevo}. ${datos.observaciones || ''}`,
    orden_id: datos.orden_id,
    estado_nuevo: datos.estado_nuevo,
    timestamp: new Date(),
    leida: false,
    para_roles: ['ADMINISTRADOR', 'GERENTE', 'VENDEDOR'],
  };

  notificaciones.set(notif.id, notif);
  console.log(`📢 Notificación estado: ${notif.titulo}`);
  
  return notif;
}

/**
 * Obtener notificaciones no leídas para un rol
 */
function obtenerNotificacionesNoLeidas(rolNombre) {
  const notifs = Array.from(notificaciones.values())
    .filter(n => n.para_roles.includes(rolNombre) && !n.leida)
    .sort((a, b) => b.timestamp - a.timestamp);

  return notifs;
}

/**
 * Obtener todas las notificaciones para un rol
 */
function obtenerTodasNotificaciones(rolNombre, limite = 50) {
  const notifs = Array.from(notificaciones.values())
    .filter(n => n.para_roles.includes(rolNombre))
    .sort((a, b) => b.timestamp - a.timestamp)
    .slice(0, limite);

  return notifs;
}

/**
 * Marcar notificación como leída
 */
function marcarComoLeida(notificacionId) {
  if (notificaciones.has(notificacionId)) {
    notificaciones.get(notificacionId).leida = true;
    console.log(`✅ Notificación ${notificacionId} marcada como leída`);
    return true;
  }
  return false;
}

/**
 * Marcar todas como leídas
 */
function marcarTodasComoLeidas(rolNombre) {
  let cantidad = 0;
  notificaciones.forEach(notif => {
    if (notif.para_roles.includes(rolNombre) && !notif.leida) {
      notif.leida = true;
      cantidad++;
    }
  });
  console.log(`✅ ${cantidad} notificaciones marcadas como leídas`);
  return cantidad;
}

/**
 * Obtener conteo de no leídas
 */
function obtenerConteoNoLeidas(rolNombre) {
  return Array.from(notificaciones.values())
    .filter(n => n.para_roles.includes(rolNombre) && !n.leida)
    .length;
}

/**
 * Limpiar notificaciones antiguas (más de 30 días)
 */
function limpiarNotificacionesAntiguas() {
  const ahora = new Date();
  const hace30Dias = new Date(ahora.getTime() - 30 * 24 * 60 * 60 * 1000);
  
  let eliminadas = 0;
  notificaciones.forEach((notif, id) => {
    if (notif.timestamp < hace30Dias && notif.leida) {
      notificaciones.delete(id);
      eliminadas++;
    }
  });

  console.log(`🗑️ ${eliminadas} notificaciones antiguas eliminadas`);
  return eliminadas;
}

module.exports = {
  crearNotificacionOrden,
  crearNotificacionEstado,
  obtenerNotificacionesNoLeidas,
  obtenerTodasNotificaciones,
  marcarComoLeida,
  marcarTodasComoLeidas,
  obtenerConteoNoLeidas,
  limpiarNotificacionesAntiguas,
};
