const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_RUTA_ENTREGA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_RUTA_ENTREGA(:p_vehiculo_id, :p_fecha_ruta, :p_descripcion, :p_estado_ruta, :p_ruta_entrega_id); END;`,
      {
        p_vehiculo_id: data.vehiculo_id,
        p_fecha_ruta: data.fecha_ruta,
        p_descripcion: data.descripcion,
        p_estado_ruta: data.estado_ruta,
        p_ruta_entrega_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_ruta_entrega_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_RUTA_ENTREGA(:p_ruta_entrega_id, :p_vehiculo_id, :p_fecha_ruta, :p_descripcion, :p_estado_ruta); END;`,
      {
        p_ruta_entrega_id: data.ruta_entrega_id,
        p_vehiculo_id: data.vehiculo_id,
        p_fecha_ruta: data.fecha_ruta,
        p_descripcion: data.descripcion,
        p_estado_ruta: data.estado_ruta,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_RUTA_ENTREGA(:p_ruta_entrega_id); END;`,
      { p_ruta_entrega_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_RUTA_ENTREGA(:p_ruta_entrega_id, :p_cursor); END;`,
      {
        p_ruta_entrega_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_RUTA_ENTREGA(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
