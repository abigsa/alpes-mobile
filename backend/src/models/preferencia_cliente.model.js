const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PREFERENCIA_CLIENTE";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PREFERENCIA_CLIENTE(:p_cli_id, :p_categoria_id, :p_peso_preferencia, :p_pref_id); END;`,
      {
        p_cli_id: data.cli_id,
        p_categoria_id: data.categoria_id,
        p_peso_preferencia: data.peso_preferencia,
        p_pref_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_pref_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PREFERENCIA_CLIENTE(:p_pref_id, :p_cli_id, :p_categoria_id, :p_peso_preferencia); END;`,
      {
        p_pref_id: data.pref_id,
        p_cli_id: data.cli_id,
        p_categoria_id: data.categoria_id,
        p_peso_preferencia: data.peso_preferencia,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_PREFERENCIA_CLIENTE(:p_pref_id); END;`,
      { p_pref_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PREFERENCIA_CLIENTE(:p_pref_id, :p_cursor); END;`,
      {
        p_pref_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PREFERENCIA_CLIENTE(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
