const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PLAN_PRODUCCION";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PLAN_PRODUCCION(:p_producto_id, :p_cantidad, :p_periodo_inicio, :p_periodo_fin, :p_tiempo_estimado_horas, :p_plan_produccion_id); END;`,
      {
        p_producto_id: data.producto_id,
        p_cantidad: data.cantidad,
        p_periodo_inicio: data.periodo_inicio,
        p_periodo_fin: data.periodo_fin,
        p_tiempo_estimado_horas: data.tiempo_estimado_horas,
        p_plan_produccion_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_plan_produccion_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PLAN_PRODUCCION(:p_plan_produccion_id, :p_producto_id, :p_cantidad, :p_periodo_inicio, :p_periodo_fin, :p_tiempo_estimado_horas); END;`,
      {
        p_plan_produccion_id: data.plan_produccion_id,
        p_producto_id: data.producto_id,
        p_cantidad: data.cantidad,
        p_periodo_inicio: data.periodo_inicio,
        p_periodo_fin: data.periodo_fin,
        p_tiempo_estimado_horas: data.tiempo_estimado_horas,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_PLAN_PRODUCCION(:p_plan_produccion_id); END;`,
      { p_plan_produccion_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PLAN_PRODUCCION(:p_plan_produccion_id, :p_cursor); END;`,
      {
        p_plan_produccion_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PLAN_PRODUCCION(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
