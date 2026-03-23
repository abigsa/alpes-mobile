const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_RESENA_COMENTARIO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_RESENA_COMENTARIO(:p_cli_id, :p_producto_id, :p_calificacion, :p_comentario, :p_resena_at, :p_resena_id); END;`,
      {
        p_cli_id: data.cli_id,
        p_producto_id: data.producto_id,
        p_calificacion: data.calificacion,
        p_comentario: data.comentario,
        p_resena_at: data.resena_at,
        p_resena_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_resena_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_RESENA_COMENTARIO(:p_resena_id, :p_cli_id, :p_producto_id, :p_calificacion, :p_comentario, :p_resena_at); END;`,
      {
        p_resena_id: data.resena_id,
        p_cli_id: data.cli_id,
        p_producto_id: data.producto_id,
        p_calificacion: data.calificacion,
        p_comentario: data.comentario,
        p_resena_at: data.resena_at,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_RESENA_COMENTARIO(:p_resena_id); END;`,
      { p_resena_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_RESENA_COMENTARIO(:p_resena_id, :p_cursor); END;`,
      {
        p_resena_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_RESENA_COMENTARIO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
