const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CARRITO_DETALLE";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CARRITO_DETALLE(:p_carrito_id, :p_producto_id, :p_cantidad, :p_precio_unitario_snapshot, :p_carrito_det_id); END;`,
      {
        p_carrito_id: data.carrito_id,
        p_producto_id: data.producto_id,
        p_cantidad: data.cantidad,
        p_precio_unitario_snapshot: data.precio_unitario_snapshot,
        p_carrito_det_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_carrito_det_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CARRITO_DETALLE(:p_carrito_det_id, :p_carrito_id, :p_producto_id, :p_cantidad, :p_precio_unitario_snapshot); END;`,
      {
        p_carrito_det_id: data.carrito_det_id,
        p_carrito_id: data.carrito_id,
        p_producto_id: data.producto_id,
        p_cantidad: data.cantidad,
        p_precio_unitario_snapshot: data.precio_unitario_snapshot,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_CARRITO_DETALLE(:p_carrito_det_id); END;`,
      { p_carrito_det_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CARRITO_DETALLE(:p_carrito_det_id, :p_cursor); END;`,
      {
        p_carrito_det_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CARRITO_DETALLE(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
