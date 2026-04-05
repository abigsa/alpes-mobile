const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ZONA_ENVIO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_ZONA_ENVIO(:p_nombre, :p_pais, :p_departamento, :p_ciudad, :p_zona_envio_id); END;`,
      {
        p_nombre: data.nombre,
        p_pais: data.pais,
        p_departamento: data.departamento,
        p_ciudad: data.ciudad,
        p_zona_envio_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_zona_envio_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_ZONA_ENVIO(:p_zona_envio_id, :p_nombre, :p_pais, :p_departamento, :p_ciudad); END;`,
      {
        p_zona_envio_id: data.zona_envio_id,
        p_nombre: data.nombre,
        p_pais: data.pais,
        p_departamento: data.departamento,
        p_ciudad: data.ciudad,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_ZONA_ENVIO(:p_zona_envio_id); END;`,
      { p_zona_envio_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_ZONA_ENVIO(:p_zona_envio_id, :p_cursor); END;`,
      {
        p_zona_envio_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_ZONAS_ENVIO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
