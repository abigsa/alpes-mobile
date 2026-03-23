const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_REGLA_PROMOCION";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_REGLA_PROMOCION(:p_promocion_id, :p_min_compra, :p_min_items, :p_aplica_tipo_producto, :p_tope_descuento, :p_regla_promocion_id); END;`,
      {
        p_promocion_id: data.promocion_id,
        p_min_compra: data.min_compra,
        p_min_items: data.min_items,
        p_aplica_tipo_producto: data.aplica_tipo_producto,
        p_tope_descuento: data.tope_descuento,
        p_regla_promocion_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_regla_promocion_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_REGLA_PROMOCION(:p_regla_promocion_id, :p_promocion_id, :p_min_compra, :p_min_items, :p_aplica_tipo_producto, :p_tope_descuento); END;`,
      {
        p_regla_promocion_id: data.regla_promocion_id,
        p_promocion_id: data.promocion_id,
        p_min_compra: data.min_compra,
        p_min_items: data.min_items,
        p_aplica_tipo_producto: data.aplica_tipo_producto,
        p_tope_descuento: data.tope_descuento,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_REGLA_PROMOCION(:p_regla_promocion_id); END;`,
      { p_regla_promocion_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_REGLA_PROMOCION(:p_regla_promocion_id, :p_cursor); END;`,
      {
        p_regla_promocion_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_REGLAS_PROMOCION(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
