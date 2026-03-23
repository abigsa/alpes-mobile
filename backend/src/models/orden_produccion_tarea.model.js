const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ORDEN_PRODUCCION_TAREA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_ORDEN_PRODUCCION_TAREA(:p_orden_produccion_id, :p_nombre_tarea, :p_orden, :p_inicio_at, :p_fin_at, :p_emp_id_responsable, :p_estado, :p_op_tarea_id); END;`,
      {
        p_orden_produccion_id: data.orden_produccion_id,
        p_nombre_tarea: data.nombre_tarea,
        p_orden: data.orden,
        p_inicio_at: data.inicio_at,
        p_fin_at: data.fin_at,
        p_emp_id_responsable: data.emp_id_responsable,
        p_estado: data.estado,
        p_op_tarea_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_op_tarea_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_ORDEN_PRODUCCION_TAREA(:p_op_tarea_id, :p_orden_produccion_id, :p_nombre_tarea, :p_orden, :p_inicio_at, :p_fin_at, :p_emp_id_responsable, :p_estado); END;`,
      {
        p_op_tarea_id: data.op_tarea_id,
        p_orden_produccion_id: data.orden_produccion_id,
        p_nombre_tarea: data.nombre_tarea,
        p_orden: data.orden,
        p_inicio_at: data.inicio_at,
        p_fin_at: data.fin_at,
        p_emp_id_responsable: data.emp_id_responsable,
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
      `BEGIN ${PKG}.SP_ELIMINAR_ORDEN_PRODUCCION_TAREA(:p_op_tarea_id); END;`,
      { p_op_tarea_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_ORDEN_PRODUCCION_TAREA(:p_op_tarea_id, :p_cursor); END;`,
      {
        p_op_tarea_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_ORDEN_PRODUCCION_TAREA(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
