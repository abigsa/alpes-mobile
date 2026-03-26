const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PRECIO_HISTORICO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PRECIO_HISTORICO(:p_producto_id, :p_precio, :p_vigencia_inicio, :p_vigencia_fin, :p_motivo, :p_precio_hist_id); END;`,
      {
        p_producto_id: data.producto_id,
        p_precio: data.precio,
        p_vigencia_inicio: data.vigencia_inicio ? new Date(data.vigencia_inicio + "T12:00:00") : null,
        p_vigencia_fin: data.vigencia_fin ? new Date(data.vigencia_fin + "T12:00:00") : null,
        p_motivo: data.motivo,
        p_precio_hist_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_precio_hist_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PRECIO_HISTORICO(:p_precio_hist_id, :p_producto_id, :p_precio, :p_vigencia_inicio, :p_vigencia_fin, :p_motivo); END;`,
      {
        p_precio_hist_id: data.precio_hist_id,
        p_producto_id: data.producto_id,
        p_precio: data.precio,
        p_vigencia_inicio: data.vigencia_inicio ? new Date(data.vigencia_inicio + "T12:00:00") : null,
        p_vigencia_fin: data.vigencia_fin ? new Date(data.vigencia_fin + "T12:00:00") : null,
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
      `BEGIN ${PKG}.SP_ELIMINAR_PRECIO_HISTORICO(:p_precio_hist_id); END;`,
      { p_precio_hist_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PRECIO_HISTORICO(:p_precio_hist_id, :p_cursor); END;`,
      {
        p_precio_hist_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PRECIO_HISTORICO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
