const model = require("../models/orden_venta.model");
const notificacionService = require("./notificacion.service");

async function listar() { 
  return await model.listar(); 
}

async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Orden_Venta no encontrado/a" };
  return row;
}

async function buscar(c, v) {
  return await model.buscar(c, v);
}

/**
 * Crear orden - DISPARA NOTIFICACIÓN
 */
async function crear(data) {
  const id = await model.insertar(data);
  
  // ✅ Crear notificación para admins
  notificacionService.crearNotificacionOrden({
    orden_id: id,
    cliente_id: data.cli_id,
    cliente_nombre: data.cliente_nombre,
    monto: data.monto_total || 0,
  });

  console.log(`✅ Orden ${id} creada + notificación enviada`);

  return { orden_venta_id: id, ...data };
}

async function actualizar(id, data) {
  await obtener(id);
  await model.actualizar({ orden_venta_id: id, ...data });
}

async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}

/**
 * Actualizar estado - DISPARA NOTIFICACIÓN
 */
async function actualizarEstado(id, estadoOrdenId, observaciones) {
  const ordenAnterior = await obtener(id);
  
  // Actualizar en BD
  await model.actualizarEstado(id, estadoOrdenId, observaciones);
  
  // ✅ Crear notificación para admins/vendedores
  notificacionService.crearNotificacionEstado({
    orden_id: id,
    estado_anterior: ordenAnterior.ESTADO || 'DESCONOCIDO',
    estado_nuevo: estadoOrdenId,
    observaciones: observaciones,
  });

  console.log(`✅ Estado orden ${id} actualizado + notificación enviada`);
}

module.exports = { listar, obtener, crear, actualizar, actualizarEstado, eliminar, buscar };
