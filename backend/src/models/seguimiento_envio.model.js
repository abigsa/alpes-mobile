const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_SEGUIMIENTO_ENVIO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_SEGUIMIENTO_ENVIO(:p_envio_id, :p_estado_envio_id, :p_evento_at, :p_ubicacion_texto, :p_observacion, :p_seg_envio_id); END;`,
      {
        p_envio_id: data.envio_id,
        p_estado_envio_id: data.estado_envio_id,
        p_evento_at: data.evento_at,
        p_ubicacion_texto: data.ubicacion_texto,
        p_observacion: data.observacion,
        p_seg_envio_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_seg_envio_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_SEGUIMIENTO_ENVIO(:p_seg_envio_id, :p_envio_id, :p_estado_envio_id, :p_evento_at, :p_ubicacion_texto, :p_observacion); END;`,
      {
        p_seg_envio_id: data.seg_envio_id,
        p_envio_id: data.envio_id,
        p_estado_envio_id: data.estado_envio_id,
        p_evento_at: data.evento_at,
        p_ubicacion_texto: data.ubicacion_texto,
        p_observacion: data.observacion,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_SEGUIMIENTO_ENVIO(:p_seg_envio_id); END;`,
      { p_seg_envio_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_SEGUIMIENTO_ENVIO(:p_seg_envio_id, :p_cursor); END;`,
      {
        p_seg_envio_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_SEGUIMIENTO_ENVIO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
