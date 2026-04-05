const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ORDEN_COMPRA_DETALLE";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_ORDEN_COMPRA_DETALLE(:p_orden_compra_id, :p_mp_id, :p_cantidad, :p_costo_unitario, :p_subtotal_linea, :p_orden_compra_det_id); END;`,
      {
        p_orden_compra_id: data.orden_compra_id,
        p_mp_id: data.mp_id,
        p_cantidad: data.cantidad,
        p_costo_unitario: data.costo_unitario,
        p_subtotal_linea: data.subtotal_linea,
        p_orden_compra_det_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_orden_compra_det_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_ORDEN_COMPRA_DETALLE(:p_orden_compra_det_id, :p_orden_compra_id, :p_mp_id, :p_cantidad, :p_costo_unitario, :p_subtotal_linea); END;`,
      {
        p_orden_compra_det_id: data.orden_compra_det_id,
        p_orden_compra_id: data.orden_compra_id,
        p_mp_id: data.mp_id,
        p_cantidad: data.cantidad,
        p_costo_unitario: data.costo_unitario,
        p_subtotal_linea: data.subtotal_linea,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_ORDEN_COMPRA_DETALLE(:p_orden_compra_det_id); END;`,
      { p_orden_compra_det_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_ORDEN_COMPRA_DETALLE(:p_orden_compra_det_id, :p_cursor); END;`,
      {
        p_orden_compra_det_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_ORDEN_COMPRA_DETALLE(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
