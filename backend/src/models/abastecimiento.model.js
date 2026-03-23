const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ABASTECIMIENTO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_ABASTECIMIENTO(:p_mp_id, :p_cantidad_sugerida, :p_motivo, :p_abastecimiento_id); END;`,
      {
        p_mp_id: data.mp_id,
        p_cantidad_sugerida: data.cantidad_sugerida,
        p_motivo: data.motivo,
        p_abastecimiento_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_abastecimiento_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_ABASTECIMIENTO(:p_abastecimiento_id, :p_mp_id, :p_cantidad_sugerida, :p_motivo); END;`,
      {
        p_abastecimiento_id: data.abastecimiento_id,
        p_mp_id: data.mp_id,
        p_cantidad_sugerida: data.cantidad_sugerida,
        p_motivo: data.motivo,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_ABASTECIMIENTO(:p_abastecimiento_id); END;`,
      { p_abastecimiento_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_ABASTECIMIENTO(:p_abastecimiento_id, :p_cursor); END;`,
      {
        p_abastecimiento_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_ABASTECIMIENTOS(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
