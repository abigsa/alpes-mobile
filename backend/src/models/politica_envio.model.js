const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_POLITICA_ENVIO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_POLITICA_ENVIO(:p_titulo, :p_descripcion, :p_vigencia_inicio, :p_vigencia_fin, :p_politica_envio_id); END;`,
      {
        p_titulo: data.titulo,
        p_descripcion: data.descripcion,
        p_vigencia_inicio: data.vigencia_inicio ? new Date(data.vigencia_inicio + "T12:00:00") : null,
        p_vigencia_fin: data.vigencia_fin ? new Date(data.vigencia_fin + "T12:00:00") : null,
        p_politica_envio_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_politica_envio_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_POLITICA_ENVIO(:p_politica_envio_id, :p_titulo, :p_descripcion, :p_vigencia_inicio, :p_vigencia_fin); END;`,
      {
        p_politica_envio_id: data.politica_envio_id,
        p_titulo: data.titulo,
        p_descripcion: data.descripcion,
        p_vigencia_inicio: data.vigencia_inicio ? new Date(data.vigencia_inicio + "T12:00:00") : null,
        p_vigencia_fin: data.vigencia_fin ? new Date(data.vigencia_fin + "T12:00:00") : null,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_POLITICA_ENVIO(:p_politica_envio_id); END;`,
      { p_politica_envio_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_POLITICA_ENVIO(:p_politica_envio_id, :p_cursor); END;`,
      {
        p_politica_envio_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_POLITICAS_ENVIO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
