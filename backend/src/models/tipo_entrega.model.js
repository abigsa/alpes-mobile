const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_TIPO_ENTREGA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_TIPO_ENTREGA(:p_nombre, :p_descripcion, :p_tipo_entrega_id); END;`,
      {
        p_nombre: data.nombre,
        p_descripcion: data.descripcion,
        p_tipo_entrega_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_tipo_entrega_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_TIPO_ENTREGA(:p_tipo_entrega_id, :p_nombre, :p_descripcion); END;`,
      {
        p_tipo_entrega_id: data.tipo_entrega_id,
        p_nombre: data.nombre,
        p_descripcion: data.descripcion,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_TIPO_ENTREGA(:p_tipo_entrega_id); END;`,
      { p_tipo_entrega_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_TIPO_ENTREGA(:p_tipo_entrega_id, :p_cursor); END;`,
      {
        p_tipo_entrega_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_TIPO_ENTREGA(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
