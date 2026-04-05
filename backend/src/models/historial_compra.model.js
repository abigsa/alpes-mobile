const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_HISTORIAL_COMPRA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_HISTORIAL_COMPRA(:p_cli_id, :p_orden_venta_id, :p_compra_at, :p_monto_total_snapshot, :p_hist_compra_id); END;`,
      {
        p_cli_id: data.cli_id,
        p_orden_venta_id: data.orden_venta_id,
        p_compra_at: data.compra_at,
        p_monto_total_snapshot: data.monto_total_snapshot,
        p_hist_compra_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_hist_compra_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_HISTORIAL_COMPRA(:p_hist_compra_id, :p_cli_id, :p_orden_venta_id, :p_compra_at, :p_monto_total_snapshot); END;`,
      {
        p_hist_compra_id: data.hist_compra_id,
        p_cli_id: data.cli_id,
        p_orden_venta_id: data.orden_venta_id,
        p_compra_at: data.compra_at,
        p_monto_total_snapshot: data.monto_total_snapshot,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_HISTORIAL_COMPRA(:p_hist_compra_id); END;`,
      { p_hist_compra_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_HISTORIAL_COMPRA(:p_hist_compra_id, :p_cursor); END;`,
      {
        p_hist_compra_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_HISTORIAL_COMPRA(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
