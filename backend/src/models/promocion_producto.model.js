const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PROMOCION_PRODUCTO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PROMOCION_PRODUCTO(:p_promocion_id, :p_producto_id, :p_limite_unidades, :p_promocion_producto_id); END;`,
      {
        p_promocion_id: data.promocion_id,
        p_producto_id: data.producto_id,
        p_limite_unidades: data.limite_unidades,
        p_promocion_producto_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_promocion_producto_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PROMOCION_PRODUCTO(:p_promocion_producto_id, :p_promocion_id, :p_producto_id, :p_limite_unidades); END;`,
      {
        p_promocion_producto_id: data.promocion_producto_id,
        p_promocion_id: data.promocion_id,
        p_producto_id: data.producto_id,
        p_limite_unidades: data.limite_unidades,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_PROMOCION_PRODUCTO(:p_promocion_producto_id); END;`,
      { p_promocion_producto_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PROMOCION_PRODUCTO(:p_promocion_producto_id, :p_cursor); END;`,
      {
        p_promocion_producto_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PROMOCION_PRODUCTO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
