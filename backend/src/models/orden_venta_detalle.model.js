const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ORDEN_VENTA_DETALLE";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR(:p_orden_venta_id, :p_producto_id, :p_cantidad, :p_precio_unitario_snapshot, :p_subtotal_linea, :p_estado, :p_id); END;`,
      {
        p_orden_venta_id: data.orden_venta_id,
        p_producto_id: data.producto_id,
        p_cantidad: data.cantidad,
        p_precio_unitario_snapshot: data.precio_unitario_snapshot,
        p_subtotal_linea: data.subtotal_linea,
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
      `BEGIN ${PKG}.SP_ACTUALIZAR(:p_orden_venta_det_id, :p_orden_venta_id, :p_producto_id, :p_cantidad, :p_precio_unitario_snapshot, :p_subtotal_linea, :p_estado); END;`,
      {
        p_orden_venta_det_id: data.orden_venta_det_id,
        p_orden_venta_id: data.orden_venta_id,
        p_producto_id: data.producto_id,
        p_cantidad: data.cantidad,
        p_precio_unitario_snapshot: data.precio_unitario_snapshot,
        p_subtotal_linea: data.subtotal_linea,
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
