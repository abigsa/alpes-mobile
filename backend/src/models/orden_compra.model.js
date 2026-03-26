const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ORDEN_COMPRA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_ORDEN_COMPRA(:p_num_oc, :p_prov_id, :p_estado_oc_id, :p_condicion_pago_id, :p_fecha_oc, :p_subtotal, :p_impuesto, :p_total, :p_observaciones, :p_orden_compra_id); END;`,
      {
        p_num_oc: data.num_oc,
        p_prov_id: data.prov_id,
        p_estado_oc_id: data.estado_oc_id,
        p_condicion_pago_id: data.condicion_pago_id,
        p_fecha_oc: data.fecha_oc ? new Date(data.fecha_oc + "T12:00:00") : null,
        p_subtotal: data.subtotal,
        p_impuesto: data.impuesto,
        p_total: data.total,
        p_observaciones: data.observaciones,
        p_orden_compra_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_orden_compra_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_ORDEN_COMPRA(:p_orden_compra_id, :p_num_oc, :p_prov_id, :p_estado_oc_id, :p_condicion_pago_id, :p_fecha_oc, :p_subtotal, :p_impuesto, :p_total, :p_observaciones); END;`,
      {
        p_orden_compra_id: data.orden_compra_id,
        p_num_oc: data.num_oc,
        p_prov_id: data.prov_id,
        p_estado_oc_id: data.estado_oc_id,
        p_condicion_pago_id: data.condicion_pago_id,
        p_fecha_oc: data.fecha_oc ? new Date(data.fecha_oc + "T12:00:00") : null,
        p_subtotal: data.subtotal,
        p_impuesto: data.impuesto,
        p_total: data.total,
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
      `BEGIN ${PKG}.SP_ELIMINAR_ORDEN_COMPRA(:p_orden_compra_id); END;`,
      { p_orden_compra_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_ORDEN_COMPRA(:p_orden_compra_id, :p_cursor); END;`,
      {
        p_orden_compra_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_ORDENES_COMPRA(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
