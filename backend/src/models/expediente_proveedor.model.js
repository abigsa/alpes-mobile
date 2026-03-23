const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_EXPEDIENTE_PROVEEDOR";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_EXPEDIENTE_PROVEEDOR(:p_prov_id, :p_tipo_documento, :p_url_documento, :p_fecha_documento, :p_expediente_proveedor_id); END;`,
      {
        p_prov_id: data.prov_id,
        p_tipo_documento: data.tipo_documento,
        p_url_documento: data.url_documento,
        p_fecha_documento: data.fecha_documento,
        p_expediente_proveedor_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_expediente_proveedor_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_EXPEDIENTE_PROVEEDOR(:p_expediente_proveedor_id, :p_prov_id, :p_tipo_documento, :p_url_documento, :p_fecha_documento); END;`,
      {
        p_expediente_proveedor_id: data.expediente_proveedor_id,
        p_prov_id: data.prov_id,
        p_tipo_documento: data.tipo_documento,
        p_url_documento: data.url_documento,
        p_fecha_documento: data.fecha_documento,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_EXPEDIENTE_PROVEEDOR(:p_expediente_proveedor_id); END;`,
      { p_expediente_proveedor_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_EXPEDIENTE_PROVEEDOR(:p_expediente_proveedor_id, :p_cursor); END;`,
      {
        p_expediente_proveedor_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_EXPEDIENTES_PROVEEDOR(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
