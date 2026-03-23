const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_TARIFA_ENVIO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_TARIFA_ENVIO(:p_zona_envio_id, :p_tipo_entrega_id, :p_peso_desde_kg, :p_peso_hasta_kg, :p_costo, :p_tarifa_envio_id); END;`,
      {
        p_zona_envio_id: data.zona_envio_id,
        p_tipo_entrega_id: data.tipo_entrega_id,
        p_peso_desde_kg: data.peso_desde_kg,
        p_peso_hasta_kg: data.peso_hasta_kg,
        p_costo: data.costo,
        p_tarifa_envio_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_tarifa_envio_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_TARIFA_ENVIO(:p_tarifa_envio_id, :p_zona_envio_id, :p_tipo_entrega_id, :p_peso_desde_kg, :p_peso_hasta_kg, :p_costo); END;`,
      {
        p_tarifa_envio_id: data.tarifa_envio_id,
        p_zona_envio_id: data.zona_envio_id,
        p_tipo_entrega_id: data.tipo_entrega_id,
        p_peso_desde_kg: data.peso_desde_kg,
        p_peso_hasta_kg: data.peso_hasta_kg,
        p_costo: data.costo,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_TARIFA_ENVIO(:p_tarifa_envio_id); END;`,
      { p_tarifa_envio_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_TARIFA_ENVIO(:p_tarifa_envio_id, :p_cursor); END;`,
      {
        p_tarifa_envio_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_TARIFAS_ENVIO(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
