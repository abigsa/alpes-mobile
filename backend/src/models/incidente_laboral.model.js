const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_INCIDENTE_LABORAL";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.INSERTAR(:p_emp_id, :p_fecha_incidente, :p_descripcion, :p_gravedad, :p_acciones_tomadas, :p_estado, :p_incidente_id); END;`,
      {
        p_emp_id: data.emp_id,
        p_fecha_incidente: data.fecha_incidente,
        p_descripcion: data.descripcion,
        p_gravedad: data.gravedad,
        p_acciones_tomadas: data.acciones_tomadas,
        p_estado: data.estado,
        p_incidente_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_incidente_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.ACTUALIZAR(:p_incidente_id, :p_emp_id, :p_fecha_incidente, :p_descripcion, :p_gravedad, :p_acciones_tomadas, :p_estado); END;`,
      {
        p_incidente_id: data.incidente_id,
        p_emp_id: data.emp_id,
        p_fecha_incidente: data.fecha_incidente,
        p_descripcion: data.descripcion,
        p_gravedad: data.gravedad,
        p_acciones_tomadas: data.acciones_tomadas,
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
      `BEGIN ${PKG}.ELIMINAR(:p_incidente_id); END;`,
      { p_incidente_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.OBTENER_POR_ID(:p_incidente_id, :p_resultado); END;`,
      {
        p_incidente_id: id,
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
