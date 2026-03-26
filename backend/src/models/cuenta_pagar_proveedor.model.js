const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CUENTA_PAGAR_PROVEEDOR";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CUENTA_PAGAR_PROVEEDOR(:p_prov_id, :p_orden_compra_id, :p_saldo, :p_fecha_vencimiento, :p_estado_cp, :p_cuenta_pagar_id); END;`,
      {
        p_prov_id: data.prov_id,
        p_orden_compra_id: data.orden_compra_id,
        p_saldo: data.saldo,
        p_fecha_vencimiento: data.fecha_vencimiento ? new Date(data.fecha_vencimiento + "T12:00:00") : null,
        p_estado_cp: data.estado_cp,
        p_cuenta_pagar_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_cuenta_pagar_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CUENTA_PAGAR_PROVEEDOR(:p_cuenta_pagar_id, :p_prov_id, :p_orden_compra_id, :p_saldo, :p_fecha_vencimiento, :p_estado_cp); END;`,
      {
        p_cuenta_pagar_id: data.cuenta_pagar_id,
        p_prov_id: data.prov_id,
        p_orden_compra_id: data.orden_compra_id,
        p_saldo: data.saldo,
        p_fecha_vencimiento: data.fecha_vencimiento ? new Date(data.fecha_vencimiento + "T12:00:00") : null,
        p_estado_cp: data.estado_cp,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_CUENTA_PAGAR_PROVEEDOR(:p_cuenta_pagar_id); END;`,
      { p_cuenta_pagar_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CUENTA_PAGAR_PROVEEDOR(:p_cuenta_pagar_id, :p_cursor); END;`,
      {
        p_cuenta_pagar_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CUENTAS_PAGAR_PROVEEDOR(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
