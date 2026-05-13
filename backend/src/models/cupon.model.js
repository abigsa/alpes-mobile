const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CUPON";

function parseFechaFlutter(fechaStr) {
  // Recibe: "2026-05-09" de Flutter
  // Devuelve: Date object para Oracle
  if (!fechaStr) return null;
  try {
    const [year, month, day] = fechaStr.toString().split('-');
    return new Date(parseInt(year), parseInt(month) - 1, parseInt(day), 12, 0, 0);
  } catch (e) {
    return null;
  }
}

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CUPON(:p_codigo, :p_descripcion, :p_vigencia_inicio, :p_vigencia_fin, :p_limite_uso_total, :p_limite_uso_por_cliente, :p_usos_actuales, :p_cupon_id); END;`,
      {
        p_codigo: data.codigo,
        p_descripcion: data.descripcion,
        p_vigencia_inicio: parseFechaFlutter(data.vigencia_inicio),
        p_vigencia_fin: parseFechaFlutter(data.vigencia_fin),
        p_limite_uso_total: data.limite_uso_total,
        p_limite_uso_por_cliente: data.limite_uso_por_cliente,
        p_usos_actuales: data.usos_actuales || 0,
        p_cupon_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_cupon_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CUPON(:p_cupon_id, :p_codigo, :p_descripcion, :p_vigencia_inicio, :p_vigencia_fin, :p_limite_uso_total, :p_limite_uso_por_cliente, :p_usos_actuales); END;`,
      {
        p_cupon_id: data.cupon_id,
        p_codigo: data.codigo,
        p_descripcion: data.descripcion,
        p_vigencia_inicio: parseFechaFlutter(data.vigencia_inicio),
        p_vigencia_fin: parseFechaFlutter(data.vigencia_fin),
        p_limite_uso_total: data.limite_uso_total,
        p_limite_uso_por_cliente: data.limite_uso_por_cliente,
        p_usos_actuales: data.usos_actuales || 0,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_CUPON(:p_cupon_id); END;`,
      { p_cupon_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CUPON(:p_cupon_id, :p_cursor); END;`,
      {
        p_cupon_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CUPONES(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };