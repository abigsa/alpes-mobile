const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PAGO_PROVEEDOR";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PAGO_PROVEEDOR(:p_cuenta_pagar_id, :p_monto, :p_fecha_pago, :p_referencia, :p_pago_proveedor_id); END;`,
      {
        p_cuenta_pagar_id: data.cuenta_pagar_id,
        p_monto: data.monto,
        p_fecha_pago: data.fecha_pago,
        p_referencia: data.referencia,
        p_pago_proveedor_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_pago_proveedor_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PAGO_PROVEEDOR(:p_pago_proveedor_id, :p_cuenta_pagar_id, :p_monto, :p_fecha_pago, :p_referencia); END;`,
      {
        p_pago_proveedor_id: data.pago_proveedor_id,
        p_cuenta_pagar_id: data.cuenta_pagar_id,
        p_monto: data.monto,
        p_fecha_pago: data.fecha_pago,
        p_referencia: data.referencia,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_PAGO_PROVEEDOR(:p_pago_proveedor_id); END;`,
      { p_pago_proveedor_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PAGO_PROVEEDOR(:p_pago_proveedor_id, :p_cursor); END;`,
      {
        p_pago_proveedor_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PAGOS_PROVEEDOR(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
