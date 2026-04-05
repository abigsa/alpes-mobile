const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_CLIENTE";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR_CLIENTE(:p_tipo_documento, :p_num_documento, :p_nit, :p_nombres, :p_apellidos, :p_email, :p_tel_residencia, :p_tel_celular, :p_direccion, :p_ciudad, :p_departamento, :p_pais, :p_profesion, :p_cli_id); END;`,
      {
        p_tipo_documento: data.tipo_documento,
        p_num_documento: data.num_documento,
        p_nit: data.nit,
        p_nombres: data.nombres,
        p_apellidos: data.apellidos,
        p_email: data.email,
        p_tel_residencia: data.tel_residencia,
        p_tel_celular: data.tel_celular,
        p_direccion: data.direccion,
        p_ciudad: data.ciudad,
        p_departamento: data.departamento,
        p_pais: data.pais,
        p_profesion: data.profesion,
        p_cli_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_cli_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR_CLIENTE(:p_cli_id, :p_tipo_documento, :p_num_documento, :p_nit, :p_nombres, :p_apellidos, :p_email, :p_tel_residencia, :p_tel_celular, :p_direccion, :p_ciudad, :p_departamento, :p_pais, :p_profesion); END;`,
      {
        p_cli_id: data.cli_id,
        p_tipo_documento: data.tipo_documento,
        p_num_documento: data.num_documento,
        p_nit: data.nit,
        p_nombres: data.nombres,
        p_apellidos: data.apellidos,
        p_email: data.email,
        p_tel_residencia: data.tel_residencia,
        p_tel_celular: data.tel_celular,
        p_direccion: data.direccion,
        p_ciudad: data.ciudad,
        p_departamento: data.departamento,
        p_pais: data.pais,
        p_profesion: data.profesion,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR_CLIENTE(:p_cli_id); END;`,
      { p_cli_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_OBTENER_CLIENTE(:p_cli_id, :p_cursor); END;`,
      {
        p_cli_id: id,
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
      `BEGIN ${PKG}.SP_LISTAR_CLIENTES(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
