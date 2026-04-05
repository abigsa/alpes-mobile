const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_EXPEDIENTE_EMPLEADO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.INSERTAR(:p_emp_id, :p_tipo_documento, :p_url_documento, :p_fecha_documento, :p_estado, :p_expediente_empleado_id); END;`,
      {
        p_emp_id: data.emp_id,
        p_tipo_documento: data.tipo_documento,
        p_url_documento: data.url_documento,
        p_fecha_documento: data.fecha_documento ? new Date(data.fecha_documento + "T12:00:00") : null,
        p_estado: data.estado,
        p_expediente_empleado_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_expediente_empleado_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.ACTUALIZAR(:p_expediente_empleado_id, :p_emp_id, :p_tipo_documento, :p_url_documento, :p_fecha_documento, :p_estado); END;`,
      {
        p_expediente_empleado_id: data.expediente_empleado_id,
        p_emp_id: data.emp_id,
        p_tipo_documento: data.tipo_documento,
        p_url_documento: data.url_documento,
        p_fecha_documento: data.fecha_documento ? new Date(data.fecha_documento + "T12:00:00") : null,
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
      `BEGIN ${PKG}.ELIMINAR(:p_expediente_empleado_id); END;`,
      { p_expediente_empleado_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.OBTENER_POR_ID(:p_expediente_empleado_id, :p_resultado); END;`,
      {
        p_expediente_empleado_id: id,
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
