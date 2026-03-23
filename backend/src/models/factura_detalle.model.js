const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_FACTURA_DETALLE";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_FACTURA_DETALLE(:p_factura_id, :p_producto_id, :p_cantidad, :p_precio_unitario_snapshot, :p_total_linea, :p_factura_det_id); END;`,
      {
        p_factura_id: data.factura_id,
        p_producto_id: data.producto_id,
        p_cantidad: data.cantidad,
        p_precio_unitario_snapshot: data.precio_unitario_snapshot,
        p_total_linea: data.total_linea,
        p_factura_det_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_factura_det_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_FACTURA_DETALLE(:p_factura_det_id, :p_factura_id, :p_producto_id, :p_cantidad, :p_precio_unitario_snapshot, :p_total_linea); END;`,
      {
        p_factura_det_id: data.factura_det_id,
        p_factura_id: data.factura_id,
        p_producto_id: data.producto_id,
        p_cantidad: data.cantidad,
        p_precio_unitario_snapshot: data.precio_unitario_snapshot,
        p_total_linea: data.total_linea,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_FACTURA_DETALLE(:p_factura_det_id); END;`,
      { p_factura_det_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_FACTURA_DETALLE(:p_factura_det_id, :p_cursor); END;`,
      {
        p_factura_det_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_FACTURA_DETALLE(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
