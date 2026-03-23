const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_USUARIO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_INSERTAR(:p_username, :p_password_hash, :p_email, :p_telefono, :p_rol_id, :p_cli_id, :p_emp_id, :p_ultimo_login_at, :p_bloqueado_hasta, :p_estado, :p_id); END;`,
      {
        p_username: data.username,
        p_password_hash: data.password_hash,
        p_email: data.email,
        p_telefono: data.telefono,
        p_rol_id: data.rol_id,
        p_cli_id: data.cli_id,
        p_emp_id: data.emp_id,
        p_ultimo_login_at: data.ultimo_login_at,
        p_bloqueado_hasta: data.bloqueado_hasta,
        p_estado: data.estado,
        p_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ACTUALIZAR(:p_usu_id, :p_username, :p_password_hash, :p_email, :p_telefono, :p_rol_id, :p_cli_id, :p_emp_id, :p_ultimo_login_at, :p_bloqueado_hasta, :p_estado); END;`,
      {
        p_usu_id: data.usu_id,
        p_username: data.username,
        p_password_hash: data.password_hash,
        p_email: data.email,
        p_telefono: data.telefono,
        p_rol_id: data.rol_id,
        p_cli_id: data.cli_id,
        p_emp_id: data.emp_id,
        p_ultimo_login_at: data.ultimo_login_at,
        p_bloqueado_hasta: data.bloqueado_hasta,
        p_estado: data.estado,
      }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function eliminar(id) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.SP_ELIMINAR(:p_id); END;`,
      { p_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
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
  } finally { await closeConn(conn); }
}

async function listar() {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.SP_LISTAR(:p_cursor); END;`,
      { p_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_cursor);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
