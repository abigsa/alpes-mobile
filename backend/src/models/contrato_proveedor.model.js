const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CONTRATO_PROVEEDOR";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CONTRATO_PROVEEDOR(:p_prov_id, :p_titulo, :p_vigencia_inicio, :p_vigencia_fin, :p_url_documento, :p_contrato_proveedor_id); END;`,
      {
        p_prov_id: data.prov_id,
        p_titulo: data.titulo,
        p_vigencia_inicio: data.vigencia_inicio,
        p_vigencia_fin: data.vigencia_fin,
        p_url_documento: data.url_documento,
        p_contrato_proveedor_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_contrato_proveedor_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CONTRATO_PROVEEDOR(:p_contrato_proveedor_id, :p_prov_id, :p_titulo, :p_vigencia_inicio, :p_vigencia_fin, :p_url_documento); END;`,
      {
        p_contrato_proveedor_id: data.contrato_proveedor_id,
        p_prov_id: data.prov_id,
        p_titulo: data.titulo,
        p_vigencia_inicio: data.vigencia_inicio,
        p_vigencia_fin: data.vigencia_fin,
        p_url_documento: data.url_documento,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_CONTRATO_PROVEEDOR(:p_contrato_proveedor_id); END;`,
      { p_contrato_proveedor_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CONTRATO_PROVEEDOR(:p_contrato_proveedor_id, :p_cursor); END;`,
      {
        p_contrato_proveedor_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CONTRATOS_PROVEEDOR(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
