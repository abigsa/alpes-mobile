const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_INVENTARIO_PRODUCTO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_INVENTARIO_PRODUCTO(:p_producto_id, :p_stock, :p_stock_reservado, :p_stock_minimo, :p_inv_prod_id); END;`,
      {
        p_producto_id: data.producto_id,
        p_stock: data.stock,
        p_stock_reservado: data.stock_reservado,
        p_stock_minimo: data.stock_minimo,
        p_inv_prod_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_inv_prod_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_INVENTARIO_PRODUCTO(:p_inv_prod_id, :p_producto_id, :p_stock, :p_stock_reservado, :p_stock_minimo); END;`,
      {
        p_inv_prod_id: data.inv_prod_id,
        p_producto_id: data.producto_id,
        p_stock: data.stock,
        p_stock_reservado: data.stock_reservado,
        p_stock_minimo: data.stock_minimo,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_INVENTARIO_PRODUCTO(:p_inv_prod_id); END;`,
      { p_inv_prod_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_INVENTARIO_PRODUCTO(:p_inv_prod_id, :p_cursor); END;`,
      {
        p_inv_prod_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_INVENTARIO_PRODUCTO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
