const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CUOTAS_PAGO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR(:p_pago_id, :p_num_cuota, :p_monto_cuota, :p_fecha_vencimiento, :p_fecha_pago, :p_estado, :p_id); END;`,
      {
        p_pago_id: data.pago_id,
        p_num_cuota: data.num_cuota,
        p_monto_cuota: data.monto_cuota,
        p_fecha_vencimiento: data.fecha_vencimiento ? new Date(data.fecha_vencimiento + "T12:00:00") : null,
        p_fecha_pago: data.fecha_pago ? new Date(data.fecha_pago + "T12:00:00") : null,
        p_estado: data.estado,
        p_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR(:p_cuota_id, :p_pago_id, :p_num_cuota, :p_monto_cuota, :p_fecha_vencimiento, :p_fecha_pago, :p_estado); END;`,
      {
        p_cuota_id: data.cuota_id,
        p_pago_id: data.pago_id,
        p_num_cuota: data.num_cuota,
        p_monto_cuota: data.monto_cuota,
        p_fecha_vencimiento: data.fecha_vencimiento ? new Date(data.fecha_vencimiento + "T12:00:00") : null,
        p_fecha_pago: data.fecha_pago ? new Date(data.fecha_pago + "T12:00:00") : null,
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
      `BEGIN ${PKG}.SP_ELIMINAR(:p_id); END;`,
      { p_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER(:p_id, :p_cursor); END;`,
      {
        p_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
