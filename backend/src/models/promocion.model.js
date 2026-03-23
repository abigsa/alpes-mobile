const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PROMOCION";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PROMOCION(:p_tipo_promocion_id, :p_nombre, :p_descripcion, :p_vigencia_inicio, :p_vigencia_fin, :p_prioridad, :p_promocion_id); END;`,
      {
        p_tipo_promocion_id: data.tipo_promocion_id,
        p_nombre: data.nombre,
        p_descripcion: data.descripcion,
        p_vigencia_inicio: data.vigencia_inicio,
        p_vigencia_fin: data.vigencia_fin,
        p_prioridad: data.prioridad,
        p_promocion_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_promocion_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PROMOCION(:p_promocion_id, :p_tipo_promocion_id, :p_nombre, :p_descripcion, :p_vigencia_inicio, :p_vigencia_fin, :p_prioridad); END;`,
      {
        p_promocion_id: data.promocion_id,
        p_tipo_promocion_id: data.tipo_promocion_id,
        p_nombre: data.nombre,
        p_descripcion: data.descripcion,
        p_vigencia_inicio: data.vigencia_inicio,
        p_vigencia_fin: data.vigencia_fin,
        p_prioridad: data.prioridad,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_PROMOCION(:p_promocion_id); END;`,
      { p_promocion_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PROMOCION(:p_promocion_id, :p_cursor); END;`,
      {
        p_promocion_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PROMOCIONES(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
