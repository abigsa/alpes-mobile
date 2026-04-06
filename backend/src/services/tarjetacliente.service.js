const oracledb = require('oracledb');
const db = require('../config/db');
const Tarjetaclientemodel = require('../models/tarjetaclientemodel');

async function getConnection() {
  if (typeof db.getConnection === 'function') {
    return db.getConnection();
  }
  return db;
}

async function crearTarjeta(data) {
  let connection;
  try {
    connection = await getConnection();

    await connection.execute(
      `
      BEGIN
        PKG_TARJETA_CLIENTE.SP_INSERTAR_TARJETA_CLIENTE(
          P_CLI_ID           => :p_cli_id,
          P_TITULAR          => :p_titular,
          P_ULTIMOS_4        => :p_ultimos_4,
          P_MARCA            => :p_marca,
          P_MES_VENCIMIENTO  => :p_mes_vencimiento,
          P_ANIO_VENCIMIENTO => :p_anio_vencimiento,
          P_ALIAS_TARJETA    => :p_alias_tarjeta,
          P_PREDETERMINADA   => :p_predeterminada
        );
      END;
      `,
      {
        p_cli_id: data.cliId,
        p_titular: data.titular,
        p_ultimos_4: data.ultimos4,
        p_marca: data.marca,
        p_mes_vencimiento: data.mesVencimiento,
        p_anio_vencimiento: data.anioVencimiento,
        p_alias_tarjeta: data.aliasTarjeta,
        p_predeterminada: data.predeterminada ?? 0,
      },
      { autoCommit: false }
    );

    return { ok: true, message: 'Tarjeta registrada correctamente' };
  } finally {
    if (connection) await connection.close();
  }
}

async function obtenerTarjetasPorCliente(cliId) {
  let connection;
  try {
    connection = await getConnection();

    const result = await connection.execute(
      `
      BEGIN
        PKG_TARJETA_CLIENTE.SP_OBTENER_TARJETAS_CLIENTE(
          P_CLI_ID => :p_cli_id,
          P_CURSOR => :p_cursor
        );
      END;
      `,
      {
        p_cli_id: cliId,
        p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
      }
    );

    const resultSet = result.outBinds.p_cursor;
    const rows = await resultSet.getRows(1000);
    await resultSet.close();

    return rows.map((row) => new Tarjetaclientemodel(row).toJSON());
  } finally {
    if (connection) await connection.close();
  }
}

async function obtenerTarjetaPorId(tarjetaClienteId) {
  let connection;
  try {
    connection = await getConnection();

    const result = await connection.execute(
      `
      BEGIN
        PKG_TARJETA_CLIENTE.SP_OBTENER_TARJETA_POR_ID(
          P_TARJETA_CLIENTE_ID => :p_tarjeta_cliente_id,
          P_CURSOR             => :p_cursor
        );
      END;
      `,
      {
        p_tarjeta_cliente_id: tarjetaClienteId,
        p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
      }
    );

    const resultSet = result.outBinds.p_cursor;
    const rows = await resultSet.getRows(1);
    await resultSet.close();

    if (!rows || rows.length === 0) return null;

    return new Tarjetaclientemodel(rows[0]).toJSON();
  } finally {
    if (connection) await connection.close();
  }
}

async function actualizarTarjeta(tarjetaClienteId, data) {
  let connection;
  try {
    connection = await getConnection();

    await connection.execute(
      `
      BEGIN
        PKG_TARJETA_CLIENTE.SP_ACTUALIZAR_TARJETA_CLIENTE(
          P_TARJETA_CLIENTE_ID => :p_tarjeta_cliente_id,
          P_TITULAR            => :p_titular,
          P_ULTIMOS_4          => :p_ultimos_4,
          P_MARCA              => :p_marca,
          P_MES_VENCIMIENTO    => :p_mes_vencimiento,
          P_ANIO_VENCIMIENTO   => :p_anio_vencimiento,
          P_ALIAS_TARJETA      => :p_alias_tarjeta,
          P_PREDETERMINADA     => :p_predeterminada
        );
      END;
      `,
      {
        p_tarjeta_cliente_id: tarjetaClienteId,
        p_titular: data.titular,
        p_ultimos_4: data.ultimos4,
        p_marca: data.marca,
        p_mes_vencimiento: data.mesVencimiento,
        p_anio_vencimiento: data.anioVencimiento,
        p_alias_tarjeta: data.aliasTarjeta,
        p_predeterminada: data.predeterminada ?? 0,
      },
      { autoCommit: false }
    );

    return { ok: true, message: 'Tarjeta actualizada correctamente' };
  } finally {
    if (connection) await connection.close();
  }
}

async function desactivarTarjeta(tarjetaClienteId) {
  let connection;
  try {
    connection = await getConnection();

    await connection.execute(
      `
      BEGIN
        PKG_TARJETA_CLIENTE.SP_DESACTIVAR_TARJETA_CLIENTE(
          P_TARJETA_CLIENTE_ID => :p_tarjeta_cliente_id
        );
      END;
      `,
      {
        p_tarjeta_cliente_id: tarjetaClienteId,
      },
      { autoCommit: false }
    );

    return { ok: true, message: 'Tarjeta desactivada correctamente' };
  } finally {
    if (connection) await connection.close();
  }
}

async function marcarPredeterminada(tarjetaClienteId, cliId) {
  let connection;
  try {
    connection = await getConnection();

    await connection.execute(
      `
      BEGIN
        PKG_TARJETA_CLIENTE.SP_MARCAR_PREDETERMINADA(
          P_TARJETA_CLIENTE_ID => :p_tarjeta_cliente_id,
          P_CLI_ID             => :p_cli_id
        );
      END;
      `,
      {
        p_tarjeta_cliente_id: tarjetaClienteId,
        p_cli_id: cliId,
      },
      { autoCommit: false }
    );

    return { ok: true, message: 'Tarjeta marcada como predeterminada' };
  } finally {
    if (connection) await connection.close();
  }
}

module.exports = {
  crearTarjeta,
  obtenerTarjetasPorCliente,
  obtenerTarjetaPorId,
  actualizarTarjeta,
  desactivarTarjeta,
  marcarPredeterminada,
};