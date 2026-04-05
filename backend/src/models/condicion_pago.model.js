const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CONDICION_PAGO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CONDICION_PAGO(:p_nombre, :p_dias_credito, :p_descripcion, :p_condicion_pago_id); END;`,
      {
        p_nombre: data.nombre,
        p_dias_credito: data.dias_credito,
        p_descripcion: data.descripcion,
        p_condicion_pago_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_condicion_pago_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CONDICION_PAGO(:p_condicion_pago_id, :p_nombre, :p_dias_credito, :p_descripcion); END;`,
      {
        p_condicion_pago_id: data.condicion_pago_id,
        p_nombre: data.nombre,
        p_dias_credito: data.dias_credito,
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
      `BEGIN ${PKG}.SP_ELIMINAR_CONDICION_PAGO(:p_condicion_pago_id); END;`,
      { p_condicion_pago_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CONDICION_PAGO(:p_condicion_pago_id, :p_cursor); END;`,
      {
        p_condicion_pago_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CONDICIONES_PAGO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
