const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ENVIO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_ENVIO(:p_orden_venta_id, :p_estado_envio_id, :p_tipo_entrega_id, :p_zona_envio_id, :p_ruta_entrega_id, :p_direccion_entrega_snapshot, :p_costo_envio_snapshot, :p_fecha_envio, :p_fecha_entrega_estimada, :p_fecha_entrega_real, :p_tracking_codigo, :p_envio_id); END;`,
      {
        p_orden_venta_id: data.orden_venta_id,
        p_estado_envio_id: data.estado_envio_id,
        p_tipo_entrega_id: data.tipo_entrega_id,
        p_zona_envio_id: data.zona_envio_id,
        p_ruta_entrega_id: data.ruta_entrega_id,
        p_direccion_entrega_snapshot: data.direccion_entrega_snapshot,
        p_costo_envio_snapshot: data.costo_envio_snapshot,
        p_fecha_envio: data.fecha_envio ? new Date(data.fecha_envio + "T12:00:00") : null,
        p_fecha_entrega_estimada: data.fecha_entrega_estimada ? new Date(data.fecha_entrega_estimada + "T12:00:00") : null,
        p_fecha_entrega_real: data.fecha_entrega_real ? new Date(data.fecha_entrega_real + "T12:00:00") : null,
        p_tracking_codigo: data.tracking_codigo,
        p_envio_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_envio_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_ENVIO(:p_envio_id, :p_orden_venta_id, :p_estado_envio_id, :p_tipo_entrega_id, :p_zona_envio_id, :p_ruta_entrega_id, :p_direccion_entrega_snapshot, :p_costo_envio_snapshot, :p_fecha_envio, :p_fecha_entrega_estimada, :p_fecha_entrega_real, :p_tracking_codigo); END;`,
      {
        p_envio_id: data.envio_id,
        p_orden_venta_id: data.orden_venta_id,
        p_estado_envio_id: data.estado_envio_id,
        p_tipo_entrega_id: data.tipo_entrega_id,
        p_zona_envio_id: data.zona_envio_id,
        p_ruta_entrega_id: data.ruta_entrega_id,
        p_direccion_entrega_snapshot: data.direccion_entrega_snapshot,
        p_costo_envio_snapshot: data.costo_envio_snapshot,
        p_fecha_envio: data.fecha_envio ? new Date(data.fecha_envio + "T12:00:00") : null,
        p_fecha_entrega_estimada: data.fecha_entrega_estimada ? new Date(data.fecha_entrega_estimada + "T12:00:00") : null,
        p_fecha_entrega_real: data.fecha_entrega_real ? new Date(data.fecha_entrega_real + "T12:00:00") : null,
        p_tracking_codigo: data.tracking_codigo,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_ENVIO(:p_envio_id); END;`,
      { p_envio_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_ENVIO(:p_envio_id, :p_cursor); END;`,
      {
        p_envio_id: id,
        p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
      }
    );
    const rows = await readCursor(result.outBinds.p_cursor);
    return rows[0] || null;
  } finally { await closeConn(conn); }
}

async function listar() {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_LISTAR_ENVIOS(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
