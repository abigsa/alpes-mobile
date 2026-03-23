const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_MANTENIMIENTO_HERRAMIENTAS";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR(:p_herramienta_id, :p_fecha_mantenimiento, :p_tipo, :p_costo, :p_observacion, :p_estado, :p_id); END;`,
      {
        p_herramienta_id: data.herramienta_id,
        p_fecha_mantenimiento: data.fecha_mantenimiento,
        p_tipo: data.tipo,
        p_costo: data.costo,
        p_observacion: data.observacion,
        p_estado: data.estado,
        p_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR(:p_mantenimiento_id, :p_herramienta_id, :p_fecha_mantenimiento, :p_tipo, :p_costo, :p_observacion, :p_estado); END;`,
      {
        p_mantenimiento_id: data.mantenimiento_id,
        p_herramienta_id: data.herramienta_id,
        p_fecha_mantenimiento: data.fecha_mantenimiento,
        p_tipo: data.tipo,
        p_costo: data.costo,
        p_observacion: data.observacion,
        p_estado: data.estado,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR(:p_id); END;`,
      { p_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER(:p_id, :p_cursor); END;`,
      {
        p_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
