const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_REGLA_ENVIO_GRATIS";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_REGLA_ENVIO_GRATIS(:p_zona_envio_id, :p_monto_minimo, :p_peso_max_kg, :p_vigencia_inicio, :p_vigencia_fin, :p_regla_envio_gratis_id); END;`,
      {
        p_zona_envio_id: data.zona_envio_id,
        p_monto_minimo: data.monto_minimo,
        p_peso_max_kg: data.peso_max_kg,
        p_vigencia_inicio: data.vigencia_inicio,
        p_vigencia_fin: data.vigencia_fin,
        p_regla_envio_gratis_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_regla_envio_gratis_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_REGLA_ENVIO_GRATIS(:p_regla_envio_gratis_id, :p_zona_envio_id, :p_monto_minimo, :p_peso_max_kg, :p_vigencia_inicio, :p_vigencia_fin); END;`,
      {
        p_regla_envio_gratis_id: data.regla_envio_gratis_id,
        p_zona_envio_id: data.zona_envio_id,
        p_monto_minimo: data.monto_minimo,
        p_peso_max_kg: data.peso_max_kg,
        p_vigencia_inicio: data.vigencia_inicio,
        p_vigencia_fin: data.vigencia_fin,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_REGLA_ENVIO_GRATIS(:p_regla_envio_gratis_id); END;`,
      { p_regla_envio_gratis_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_REGLA_ENVIO_GRATIS(:p_regla_envio_gratis_id, :p_cursor); END;`,
      {
        p_regla_envio_gratis_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_REGLAS_ENVIO_GRATIS(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
