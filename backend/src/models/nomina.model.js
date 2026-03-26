const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_NOMINA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.INSERTAR(:p_emp_id, :p_periodo_inicio, :p_periodo_fin, :p_monto_bruto, :p_monto_neto, :p_fecha_pago, :p_estado, :p_nomina_id); END;`,
      {
        p_emp_id: data.emp_id,
        p_periodo_inicio: data.periodo_inicio ? new Date(data.periodo_inicio + "T12:00:00") : null,
        p_periodo_fin: data.periodo_fin ? new Date(data.periodo_fin + "T12:00:00") : null,
        p_monto_bruto: data.monto_bruto,
        p_monto_neto: data.monto_neto,
        p_fecha_pago: data.fecha_pago ? new Date(data.fecha_pago + "T12:00:00") : null,
        p_estado: data.estado,
        p_nomina_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_nomina_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.ACTUALIZAR(:p_nomina_id, :p_emp_id, :p_periodo_inicio, :p_periodo_fin, :p_monto_bruto, :p_monto_neto, :p_fecha_pago, :p_estado); END;`,
      {
        p_nomina_id: data.nomina_id,
        p_emp_id: data.emp_id,
        p_periodo_inicio: data.periodo_inicio ? new Date(data.periodo_inicio + "T12:00:00") : null,
        p_periodo_fin: data.periodo_fin ? new Date(data.periodo_fin + "T12:00:00") : null,
        p_monto_bruto: data.monto_bruto,
        p_monto_neto: data.monto_neto,
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
      `BEGIN ${PKG}.ELIMINAR(:p_nomina_id); END;`,
      { p_nomina_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.OBTENER_POR_ID(:p_nomina_id, :p_resultado); END;`,
      {
        p_nomina_id: id,
        p_resultado: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
      }
    );
    const rows = await readCursor(result.outBinds.p_resultado);
    return rows[0] || null;
  } finally { await closeConn(conn); }
}

async function listar() {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.LISTAR(:p_resultado); END;`,
      { p_resultado: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_resultado);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
