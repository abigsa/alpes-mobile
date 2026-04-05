const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_LISTA_DESEOS";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_LISTA_DESEOS(:p_cli_id, :p_producto_id, :p_nota, :p_lista_deseos_id); END;`,
      {
        p_cli_id: data.cli_id,
        p_producto_id: data.producto_id,
        p_nota: data.nota,
        p_lista_deseos_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_lista_deseos_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_LISTA_DESEOS(:p_lista_deseos_id, :p_cli_id, :p_producto_id, :p_nota); END;`,
      {
        p_lista_deseos_id: data.lista_deseos_id,
        p_cli_id: data.cli_id,
        p_producto_id: data.producto_id,
        p_nota: data.nota,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_LISTA_DESEOS(:p_lista_deseos_id); END;`,
      { p_lista_deseos_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_LISTA_DESEOS(:p_lista_deseos_id, :p_cursor); END;`,
      {
        p_lista_deseos_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_LISTA_DESEOS(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
