const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PROVEEDOR";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PROVEEDOR(:p_razon_social, :p_nit, :p_email, :p_telefono, :p_direccion, :p_ciudad, :p_pais, :p_prov_id); END;`,
      {
        p_razon_social: data.razon_social,
        p_nit: data.nit,
        p_email: data.email,
        p_telefono: data.telefono,
        p_direccion: data.direccion,
        p_ciudad: data.ciudad,
        p_pais: data.pais,
        p_prov_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_prov_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PROVEEDOR(:p_prov_id, :p_razon_social, :p_nit, :p_email, :p_telefono, :p_direccion, :p_ciudad, :p_pais); END;`,
      {
        p_prov_id: data.prov_id,
        p_razon_social: data.razon_social,
        p_nit: data.nit,
        p_email: data.email,
        p_telefono: data.telefono,
        p_direccion: data.direccion,
        p_ciudad: data.ciudad,
        p_pais: data.pais,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_PROVEEDOR(:p_prov_id); END;`,
      { p_prov_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PROVEEDOR(:p_prov_id, :p_cursor); END;`,
      {
        p_prov_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PROVEEDORES(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
