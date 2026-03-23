const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ORDEN_PRODUCCION";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_ORDEN_PRODUCCION(:p_num_op, :p_producto_id, :p_cantidad_planificada, :p_estado_produccion_id, :p_inicio_estimado, :p_fin_estimado, :p_inicio_real, :p_fin_real, :p_estado, :p_orden_produccion_id); END;`,
      {
        p_num_op: data.num_op,
        p_producto_id: data.producto_id,
        p_cantidad_planificada: data.cantidad_planificada,
        p_estado_produccion_id: data.estado_produccion_id,
        p_inicio_estimado: data.inicio_estimado,
        p_fin_estimado: data.fin_estimado,
        p_inicio_real: data.inicio_real,
        p_fin_real: data.fin_real,
        p_estado: data.estado,
        p_orden_produccion_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_orden_produccion_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_ORDEN_PRODUCCION(:p_orden_produccion_id, :p_num_op, :p_producto_id, :p_cantidad_planificada, :p_estado_produccion_id, :p_inicio_estimado, :p_fin_estimado, :p_inicio_real, :p_fin_real, :p_estado); END;`,
      {
        p_orden_produccion_id: data.orden_produccion_id,
        p_num_op: data.num_op,
        p_producto_id: data.producto_id,
        p_cantidad_planificada: data.cantidad_planificada,
        p_estado_produccion_id: data.estado_produccion_id,
        p_inicio_estimado: data.inicio_estimado,
        p_fin_estimado: data.fin_estimado,
        p_inicio_real: data.inicio_real,
        p_fin_real: data.fin_real,
        p_estado: data.estado,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_ORDEN_PRODUCCION(:p_orden_produccion_id); END;`,
      { p_orden_produccion_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_ORDEN_PRODUCCION(:p_orden_produccion_id, :p_cursor); END;`,
      {
        p_orden_produccion_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_ORDEN_PRODUCCION(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
