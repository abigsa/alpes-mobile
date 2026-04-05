const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_HISTORIAL_PROMOCION";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_HISTORIAL_PROMOCION(:p_orden_venta_id, :p_promocion_id, :p_monto_descuento_snapshot, :p_historial_promocion_id); END;`,
      {
        p_orden_venta_id: data.orden_venta_id,
        p_promocion_id: data.promocion_id,
        p_monto_descuento_snapshot: data.monto_descuento_snapshot,
        p_historial_promocion_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_historial_promocion_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_HISTORIAL_PROMOCION(:p_historial_promocion_id, :p_orden_venta_id, :p_promocion_id, :p_monto_descuento_snapshot); END;`,
      {
        p_historial_promocion_id: data.historial_promocion_id,
        p_orden_venta_id: data.orden_venta_id,
        p_promocion_id: data.promocion_id,
        p_monto_descuento_snapshot: data.monto_descuento_snapshot,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_HISTORIAL_PROMOCION(:p_historial_promocion_id); END;`,
      { p_historial_promocion_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_HISTORIAL_PROMOCION(:p_historial_promocion_id, :p_cursor); END;`,
      {
        p_historial_promocion_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_HISTORIAL_PROMOCION(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
