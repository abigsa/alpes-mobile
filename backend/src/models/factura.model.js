const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_FACTURA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_FACTURA(:p_orden_venta_id, :p_num_factura, :p_fecha_emision, :p_nit_facturacion, :p_direccion_facturacion_snapshot, :p_total_factura_snapshot, :p_factura_id); END;`,
      {
        p_orden_venta_id: data.orden_venta_id,
        p_num_factura: data.num_factura,
        p_fecha_emision: data.fecha_emision,
        p_nit_facturacion: data.nit_facturacion,
        p_direccion_facturacion_snapshot: data.direccion_facturacion_snapshot,
        p_total_factura_snapshot: data.total_factura_snapshot,
        p_factura_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_factura_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_FACTURA(:p_factura_id, :p_orden_venta_id, :p_num_factura, :p_fecha_emision, :p_nit_facturacion, :p_direccion_facturacion_snapshot, :p_total_factura_snapshot); END;`,
      {
        p_factura_id: data.factura_id,
        p_orden_venta_id: data.orden_venta_id,
        p_num_factura: data.num_factura,
        p_fecha_emision: data.fecha_emision,
        p_nit_facturacion: data.nit_facturacion,
        p_direccion_facturacion_snapshot: data.direccion_facturacion_snapshot,
        p_total_factura_snapshot: data.total_factura_snapshot,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_FACTURA(:p_factura_id); END;`,
      { p_factura_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_FACTURA(:p_factura_id, :p_cursor); END;`,
      {
        p_factura_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_FACTURAS(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
