const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_ORDEN_VENTA";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR(:p_num_orden, :p_cli_id, :p_estado_orden_id, :p_fecha_orden, :p_subtotal, :p_descuento, :p_impuesto, :p_total, :p_moneda, :p_direccion_envio_snapshot, :p_observaciones, :p_estado, :p_id); END;`,
      {
        p_num_orden: data.num_orden,
        p_cli_id: data.cli_id,
        p_estado_orden_id: data.estado_orden_id,
        p_fecha_orden: data.fecha_orden
          ? new Date(data.fecha_orden + "T12:00:00")
          : null,
        p_subtotal: data.subtotal,
        p_descuento: data.descuento,
        p_impuesto: data.impuesto,
        p_total: data.total,
        p_moneda: data.moneda,
        p_direccion_envio_snapshot: data.direccion_envio_snapshot,
        p_observaciones: data.observaciones,
        p_estado: data.estado,
        p_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_id;
  } finally {
    await closeConn(conn);
  }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR(:p_orden_venta_id, :p_num_orden, :p_cli_id, :p_estado_orden_id, :p_fecha_orden, :p_subtotal, :p_descuento, :p_impuesto, :p_total, :p_moneda, :p_direccion_envio_snapshot, :p_observaciones, :p_estado); END;`,
      {
        p_orden_venta_id: data.orden_venta_id,
        p_num_orden: data.num_orden,
        p_cli_id: data.cli_id,
        p_estado_orden_id: data.estado_orden_id,
        p_fecha_orden: data.fecha_orden
          ? new Date(data.fecha_orden + "T12:00:00")
          : null,
        p_subtotal: data.subtotal,
        p_descuento: data.descuento,
        p_impuesto: data.impuesto,
        p_total: data.total,
        p_moneda: data.moneda,
        p_direccion_envio_snapshot: data.direccion_envio_snapshot,
        p_observaciones: data.observaciones,
        p_estado: data.estado,
      }
    );
    await conn.commit();
  } finally {
    await closeConn(conn);
  }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR(:p_id); END;`,
      { p_id: id }
    );
    await conn.commit();
  } finally {
    await closeConn(conn);
  }
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
  } finally {
    await closeConn(conn);
  }
}

async function listar() {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_LISTAR(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally {
    await closeConn(conn);
  }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };