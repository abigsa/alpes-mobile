const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_NOMINA_DETALLE";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.INSERTAR(:p_nomina_id, :p_tipo, :p_concepto, :p_monto, :p_estado, :p_nomina_detalle_id); END;`,
      {
        p_nomina_id: data.nomina_id,
        p_tipo: data.tipo,
        p_concepto: data.concepto,
        p_monto: data.monto,
        p_estado: data.estado,
        p_nomina_detalle_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_nomina_detalle_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.ACTUALIZAR(:p_nomina_detalle_id, :p_nomina_id, :p_tipo, :p_concepto, :p_monto, :p_estado); END;`,
      {
        p_nomina_detalle_id: data.nomina_detalle_id,
        p_nomina_id: data.nomina_id,
        p_tipo: data.tipo,
        p_concepto: data.concepto,
        p_monto: data.monto,
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
      `BEGIN ${PKG}.ELIMINAR(:p_nomina_detalle_id); END;`,
      { p_nomina_detalle_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.OBTENER_POR_ID(:p_nomina_detalle_id, :p_resultado); END;`,
      {
        p_nomina_detalle_id: id,
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
