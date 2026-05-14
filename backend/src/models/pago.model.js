const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PAGO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `INSERT INTO PAGO (ORDEN_VENTA_ID, METODO_PAGO_ID, MONTO, ESTADO_PAGO, REFERENCIA, PAGO_AT, ESTADO) 
       VALUES (:p_orden_venta_id, :p_metodo_pago_id, :p_monto, :p_estado_pago, :p_referencia, :p_pago_at, :p_estado)
       RETURNING PAGO_ID INTO :p_id`,
      {
        p_orden_venta_id: data.orden_venta_id,
        p_metodo_pago_id: data.metodo_pago_id,
        p_monto: data.monto,
        p_estado_pago: data.estado_pago,
        p_referencia: data.referencia,
        p_pago_at: data.pago_at,
        p_estado: data.estado,
        p_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_id[0];
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `UPDATE PAGO SET ORDEN_VENTA_ID = :p_orden_venta_id, METODO_PAGO_ID = :p_metodo_pago_id, 
       MONTO = :p_monto, ESTADO_PAGO = :p_estado_pago, REFERENCIA = :p_referencia, 
       PAGO_AT = :p_pago_at, ESTADO = :p_estado WHERE PAGO_ID = :p_pago_id`,
      {
        p_pago_id: data.pago_id,
        p_orden_venta_id: data.orden_venta_id,
        p_metodo_pago_id: data.metodo_pago_id,
        p_monto: data.monto,
        p_estado_pago: data.estado_pago,
        p_referencia: data.referencia,
        p_pago_at: data.pago_at,
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
      `DELETE FROM PAGO WHERE PAGO_ID = :p_id`,
      { p_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `SELECT * FROM PAGO WHERE PAGO_ID = :p_id`,
      { p_id: id }
    );
    return result.rows && result.rows.length > 0 ? result.rows[0] : null;
  } finally { await closeConn(conn); }
}

async function listar() {
  const conn = await getConnection();
  try {
    const result = await conn.execute(`SELECT * FROM PAGO`);
    return result.rows || [];
  } finally { await closeConn(conn); }
}

async function buscar(criterio, valor) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `SELECT * FROM PAGO WHERE ${criterio} = :p_valor`,
      { p_valor: valor }
    );
    return result.rows || [];
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar, buscar };
