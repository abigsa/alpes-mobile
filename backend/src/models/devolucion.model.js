const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_DEVOLUCION";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_DEVOLUCION(:p_orden_venta_id, :p_cli_id, :p_motivo, :p_estado_devolucion, :p_solicitud_at, :p_resolucion_at, :p_devolucion_id); END;`,
      {
        p_orden_venta_id: data.orden_venta_id,
        p_cli_id: data.cli_id,
        p_motivo: data.motivo,
        p_estado_devolucion: data.estado_devolucion,
        p_solicitud_at: data.solicitud_at,
        p_resolucion_at: data.resolucion_at,
        p_devolucion_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_devolucion_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_DEVOLUCION(:p_devolucion_id, :p_orden_venta_id, :p_cli_id, :p_motivo, :p_estado_devolucion, :p_solicitud_at, :p_resolucion_at); END;`,
      {
        p_devolucion_id: data.devolucion_id,
        p_orden_venta_id: data.orden_venta_id,
        p_cli_id: data.cli_id,
        p_motivo: data.motivo,
        p_estado_devolucion: data.estado_devolucion,
        p_solicitud_at: data.solicitud_at,
        p_resolucion_at: data.resolucion_at,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_DEVOLUCION(:p_devolucion_id); END;`,
      { p_devolucion_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_DEVOLUCION(:p_devolucion_id, :p_cursor); END;`,
      {
        p_devolucion_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_DEVOLUCION(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
