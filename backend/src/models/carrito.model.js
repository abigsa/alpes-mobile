const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CARRITO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CARRITO(:p_cli_id, :p_estado_carrito, :p_ultimo_calculo_at, :p_carrito_id); END;`,
      {
        p_cli_id: data.cli_id,
        p_estado_carrito: data.estado_carrito,
        p_ultimo_calculo_at: data.ultimo_calculo_at,
        p_carrito_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_carrito_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CARRITO(:p_carrito_id, :p_cli_id, :p_estado_carrito, :p_ultimo_calculo_at); END;`,
      {
        p_carrito_id: data.carrito_id,
        p_cli_id: data.cli_id,
        p_estado_carrito: data.estado_carrito,
        p_ultimo_calculo_at: data.ultimo_calculo_at,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_CARRITO(:p_carrito_id); END;`,
      { p_carrito_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CARRITO(:p_carrito_id, :p_cursor); END;`,
      {
        p_carrito_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CARRITO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
