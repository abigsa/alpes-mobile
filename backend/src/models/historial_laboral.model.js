const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_HISTORIAL_LABORAL";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.INSERTAR(:p_emp_id, :p_fecha_cambio, :p_tipo_cambio, :p_detalle, :p_estado, :p_historial_laboral_id); END;`,
      {
        p_emp_id: data.emp_id,
        p_fecha_cambio: data.fecha_cambio ? new Date(data.fecha_cambio + "T12:00:00") : null,
        p_tipo_cambio: data.tipo_cambio,
        p_detalle: data.detalle,
        p_estado: data.estado,
        p_historial_laboral_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_historial_laboral_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.ACTUALIZAR(:p_historial_laboral_id, :p_emp_id, :p_fecha_cambio, :p_tipo_cambio, :p_detalle, :p_estado); END;`,
      {
        p_historial_laboral_id: data.historial_laboral_id,
        p_emp_id: data.emp_id,
        p_fecha_cambio: data.fecha_cambio ? new Date(data.fecha_cambio + "T12:00:00") : null,
        p_tipo_cambio: data.tipo_cambio,
        p_detalle: data.detalle,
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
      `BEGIN ${PKG}.ELIMINAR(:p_historial_laboral_id); END;`,
      { p_historial_laboral_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.OBTENER_POR_ID(:p_historial_laboral_id, :p_resultado); END;`,
      {
        p_historial_laboral_id: id,
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
