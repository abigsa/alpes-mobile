const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CAMPANA_MARKETING";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CAMPANA_MARKETING(:p_nombre, :p_canal, :p_presupuesto, :p_inicio, :p_fin, :p_campana_marketing_id); END;`,
      {
        p_nombre: data.nombre,
        p_canal: data.canal,
        p_presupuesto: data.presupuesto,
        p_inicio: data.inicio ? new Date(data.inicio + "T12:00:00") : null,
        p_fin: data.fin ? new Date(data.fin + "T12:00:00") : null,
        p_campana_marketing_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_campana_marketing_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CAMPANA_MARKETING(:p_campana_marketing_id, :p_nombre, :p_canal, :p_presupuesto, :p_inicio, :p_fin); END;`,
      {
        p_campana_marketing_id: data.campana_marketing_id,
        p_nombre: data.nombre,
        p_canal: data.canal,
        p_presupuesto: data.presupuesto,
        p_inicio: data.inicio ? new Date(data.inicio + "T12:00:00") : null,
        p_fin: data.fin ? new Date(data.fin + "T12:00:00") : null,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_CAMPANA_MARKETING(:p_campana_marketing_id); END;`,
      { p_campana_marketing_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CAMPANA_MARKETING(:p_campana_marketing_id, :p_cursor); END;`,
      {
        p_campana_marketing_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CAMPANA_MARKETING(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
