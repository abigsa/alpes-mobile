const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_RECEPCION_MATERIAL";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_RECEPCION_MATERIAL(:p_orden_compra_id, :p_fecha_recepcion, :p_emp_id_recibe, :p_observaciones, :p_recepcion_material_id); END;`,
      {
        p_orden_compra_id: data.orden_compra_id,
        p_fecha_recepcion: data.fecha_recepcion ? new Date(data.fecha_recepcion + "T12:00:00") : null,
        p_emp_id_recibe: data.emp_id_recibe,
        p_observaciones: data.observaciones,
        p_recepcion_material_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_recepcion_material_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_RECEPCION_MATERIAL(:p_recepcion_material_id, :p_orden_compra_id, :p_fecha_recepcion, :p_emp_id_recibe, :p_observaciones); END;`,
      {
        p_recepcion_material_id: data.recepcion_material_id,
        p_orden_compra_id: data.orden_compra_id,
        p_fecha_recepcion: data.fecha_recepcion ? new Date(data.fecha_recepcion + "T12:00:00") : null,
        p_emp_id_recibe: data.emp_id_recibe,
        p_observaciones: data.observaciones,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_RECEPCION_MATERIAL(:p_recepcion_material_id); END;`,
      { p_recepcion_material_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_RECEPCION_MATERIAL(:p_recepcion_material_id, :p_cursor); END;`,
      {
        p_recepcion_material_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_RECEPCIONES_MATERIAL(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
