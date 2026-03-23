const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_VEHICULO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_VEHICULO(:p_placa, :p_tipo, :p_capacidad_kg, :p_capacidad_m3, :p_activo, :p_vehiculo_id); END;`,
      {
        p_placa: data.placa,
        p_tipo: data.tipo,
        p_capacidad_kg: data.capacidad_kg,
        p_capacidad_m3: data.capacidad_m3,
        p_activo: data.activo,
        p_vehiculo_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_vehiculo_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_VEHICULO(:p_vehiculo_id, :p_placa, :p_tipo, :p_capacidad_kg, :p_capacidad_m3, :p_activo); END;`,
      {
        p_vehiculo_id: data.vehiculo_id,
        p_placa: data.placa,
        p_tipo: data.tipo,
        p_capacidad_kg: data.capacidad_kg,
        p_capacidad_m3: data.capacidad_m3,
        p_activo: data.activo,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_VEHICULO(:p_vehiculo_id); END;`,
      { p_vehiculo_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_VEHICULO(:p_vehiculo_id, :p_cursor); END;`,
      {
        p_vehiculo_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_VEHICULOS(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
