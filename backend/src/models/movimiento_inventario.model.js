const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_MOVIMIENTO_INVENTARIO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_MOVIMIENTO_INVENTARIO(:p_inv_prod_id, :p_tipo_mov, :p_cantidad, :p_motivo, :p_referencia_id, :p_mov_at, :p_mov_inv_id); END;`,
      {
        p_inv_prod_id: data.inv_prod_id,
        p_tipo_mov: data.tipo_mov,
        p_cantidad: data.cantidad,
        p_motivo: data.motivo,
        p_referencia_id: data.referencia_id,
        p_mov_at: data.mov_at,
        p_mov_inv_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_mov_inv_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_MOVIMIENTO_INVENTARIO(:p_mov_inv_id, :p_inv_prod_id, :p_tipo_mov, :p_cantidad, :p_motivo, :p_referencia_id, :p_mov_at); END;`,
      {
        p_mov_inv_id: data.mov_inv_id,
        p_inv_prod_id: data.inv_prod_id,
        p_tipo_mov: data.tipo_mov,
        p_cantidad: data.cantidad,
        p_motivo: data.motivo,
        p_referencia_id: data.referencia_id,
        p_mov_at: data.mov_at,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_MOVIMIENTO_INVENTARIO(:p_mov_inv_id); END;`,
      { p_mov_inv_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_MOVIMIENTO_INVENTARIO(:p_mov_inv_id, :p_cursor); END;`,
      {
        p_mov_inv_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_MOVIMIENTO_INVENTARIO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
