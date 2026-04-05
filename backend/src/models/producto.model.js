const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_PRODUCTO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_PRODUCTO(:p_referencia, :p_nombre, :p_descripcion, :p_tipo, :p_material, :p_alto_cm, :p_ancho_cm, :p_profundidad_cm, :p_color, :p_peso_gramos, :p_imagen_url, :p_unidad_medida_id, :p_categoria_id, :p_lote_producto, :p_producto_id); END;`,
      {
        p_referencia: data.referencia,
        p_nombre: data.nombre,
        p_descripcion: data.descripcion,
        p_tipo: data.tipo,
        p_material: data.material,
        p_alto_cm: data.alto_cm,
        p_ancho_cm: data.ancho_cm,
        p_profundidad_cm: data.profundidad_cm,
        p_color: data.color,
        p_peso_gramos: data.peso_gramos,
        p_imagen_url: data.imagen_url,
        p_unidad_medida_id: data.unidad_medida_id,
        p_categoria_id: data.categoria_id,
        p_lote_producto: data.lote_producto,
        p_producto_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_producto_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_PRODUCTO(:p_producto_id, :p_referencia, :p_nombre, :p_descripcion, :p_tipo, :p_material, :p_alto_cm, :p_ancho_cm, :p_profundidad_cm, :p_color, :p_peso_gramos, :p_imagen_url, :p_unidad_medida_id, :p_categoria_id, :p_lote_producto); END;`,
      {
        p_producto_id: data.producto_id,
        p_referencia: data.referencia,
        p_nombre: data.nombre,
        p_descripcion: data.descripcion,
        p_tipo: data.tipo,
        p_material: data.material,
        p_alto_cm: data.alto_cm,
        p_ancho_cm: data.ancho_cm,
        p_profundidad_cm: data.profundidad_cm,
        p_color: data.color,
        p_peso_gramos: data.peso_gramos,
        p_imagen_url: data.imagen_url,
        p_unidad_medida_id: data.unidad_medida_id,
        p_categoria_id: data.categoria_id,
        p_lote_producto: data.lote_producto,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_PRODUCTO(:p_producto_id); END;`,
      { p_producto_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_PRODUCTO(:p_producto_id, :p_cursor); END;`,
      {
        p_producto_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_PRODUCTOS(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
