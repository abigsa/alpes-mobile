const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_TARJETA_CLIENTE";

async function insertar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_TARJETA_CLIENTE(:p_cli_id, :p_titular, :p_ultimos_4, :p_marca, :p_mes_vencimiento, :p_anio_vencimiento, :p_alias_tarjeta, :p_predeterminada); END;`,
      {
        p_cli_id: data.cli_id,
        p_titular: data.titular,
        p_ultimos_4: data.ultimos_4,
        p_marca: data.marca,
        p_mes_vencimiento: data.mes_vencimiento,
        p_anio_vencimiento: data.anio_vencimiento,
        p_alias_tarjeta: data.alias_tarjeta,
        p_predeterminada: data.predeterminada ?? 0,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function listarPorCliente(cliId) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_TARJETAS_CLIENTE(:p_cli_id, :p_cursor); END;`,
      {
        p_cli_id: cliId,
        p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
      }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

async function actualizar(id, data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_TARJETA_CLIENTE(:p_tarjeta_cliente_id, :p_titular, :p_ultimos_4, :p_marca, :p_mes_vencimiento, :p_anio_vencimiento, :p_alias_tarjeta, :p_predeterminada); END;`,
      {
        p_tarjeta_cliente_id: id,
        p_titular: data.titular,
        p_ultimos_4: data.ultimos_4,
        p_marca: data.marca,
        p_mes_vencimiento: data.mes_vencimiento,
        p_anio_vencimiento: data.anio_vencimiento,
        p_alias_tarjeta: data.alias_tarjeta,
        p_predeterminada: data.predeterminada ?? 0,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function desactivar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_DESACTIVAR_TARJETA_CLIENTE(:p_tarjeta_cliente_id); END;`,
      { p_tarjeta_cliente_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function marcarPredeterminada(id, cliId) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_MARCAR_PREDETERMINADA(:p_tarjeta_cliente_id, :p_cli_id); END;`,
      { p_tarjeta_cliente_id: id, p_cli_id: cliId }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

module.exports = { insertar, listarPorCliente, actualizar, desactivar, marcarPredeterminada };