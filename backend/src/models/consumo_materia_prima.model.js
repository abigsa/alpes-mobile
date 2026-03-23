const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CONSUMO_MATERIA_PRIMA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CONSUMO_MATERIA_PRIMA(:p_orden_produccion_id, :p_mp_id, :p_cantidad, :p_consumo_at, :p_estado, :p_consumo_id); END;`,
      {
        p_orden_produccion_id: data.orden_produccion_id,
        p_mp_id: data.mp_id,
        p_cantidad: data.cantidad,
        p_consumo_at: data.consumo_at,
        p_estado: data.estado,
        p_consumo_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_consumo_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CONSUMO_MATERIA_PRIMA(:p_consumo_id, :p_orden_produccion_id, :p_mp_id, :p_cantidad, :p_consumo_at, :p_estado); END;`,
      {
        p_consumo_id: data.consumo_id,
        p_orden_produccion_id: data.orden_produccion_id,
        p_mp_id: data.mp_id,
        p_cantidad: data.cantidad,
        p_consumo_at: data.consumo_at,
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
      `BEGIN ${PKG}.SP_ELIMINAR_CONSUMO_MATERIA_PRIMA(:p_consumo_id); END;`,
      { p_consumo_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CONSUMO_MATERIA_PRIMA(:p_consumo_id, :p_cursor); END;`,
      {
        p_consumo_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CONSUMO_MATERIA_PRIMA(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
