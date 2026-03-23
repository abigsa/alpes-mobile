const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PRODUCCION_RESULTADOS";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PRODUCCION_RESULTADOS(:p_orden_produccion_id, :p_unidades_buenas, :p_unidades_merma, :p_registro_at, :p_estado, :p_resultado_id); END;`,
      {
        p_orden_produccion_id: data.orden_produccion_id,
        p_unidades_buenas: data.unidades_buenas,
        p_unidades_merma: data.unidades_merma,
        p_registro_at: data.registro_at,
        p_estado: data.estado,
        p_resultado_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_resultado_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PRODUCCION_RESULTADOS(:p_resultado_id, :p_orden_produccion_id, :p_unidades_buenas, :p_unidades_merma, :p_registro_at, :p_estado); END;`,
      {
        p_resultado_id: data.resultado_id,
        p_orden_produccion_id: data.orden_produccion_id,
        p_unidades_buenas: data.unidades_buenas,
        p_unidades_merma: data.unidades_merma,
        p_registro_at: data.registro_at,
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
      `BEGIN ${PKG}.SP_ELIMINAR_PRODUCCION_RESULTADOS(:p_resultado_id); END;`,
      { p_resultado_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PRODUCCION_RESULTADOS(:p_resultado_id, :p_cursor); END;`,
      {
        p_resultado_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PRODUCCION_RESULTADOS(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
