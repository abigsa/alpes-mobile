const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CONTROL_CALIDAD";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR(:p_origen, :p_orden_produccion_id, :p_recepcion_material_id, :p_resultado, :p_observacion, :p_inspeccion_at, :p_estado, :p_id); END;`,
      {
        p_origen: data.origen,
        p_orden_produccion_id: data.orden_produccion_id,
        p_recepcion_material_id: data.recepcion_material_id,
        p_resultado: data.resultado,
        p_observacion: data.observacion,
        p_inspeccion_at: data.inspeccion_at,
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
      `BEGIN ${PKG}.SP_ACTUALIZAR(:p_control_calidad_id, :p_origen, :p_orden_produccion_id, :p_recepcion_material_id, :p_resultado, :p_observacion, :p_inspeccion_at, :p_estado); END;`,
      {
        p_control_calidad_id: data.control_calidad_id,
        p_origen: data.origen,
        p_orden_produccion_id: data.orden_produccion_id,
        p_recepcion_material_id: data.recepcion_material_id,
        p_resultado: data.resultado,
        p_observacion: data.observacion,
        p_inspeccion_at: data.inspeccion_at,
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
