const oracledb = require("oracledb");
const { getConnection } = require("../config/db");
const { readCursor, closeConn } = require("../utils/oracle");
const PKG = "PKG_EMPLEADO";

async function insertar(data) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.INSERTAR(:p_depto_id, :p_cargo_id, :p_rol_empleado_id, :p_nombres, :p_apellidos, :p_email, :p_telefono, :p_fecha_ingreso, :p_salario_base, :p_estado, :p_emp_id); END;`,
      {
        p_depto_id: data.depto_id,
        p_cargo_id: data.cargo_id,
        p_rol_empleado_id: data.rol_empleado_id,
        p_nombres: data.nombres,
        p_apellidos: data.apellidos,
        p_email: data.email,
        p_telefono: data.telefono,
        p_fecha_ingreso: new Date(data.fecha_ingreso),
        p_salario_base: data.salario_base,
        p_estado: data.estado,
        p_emp_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      }
    );
    await conn.commit();
    return result.outBinds.p_emp_id;
  } finally { await closeConn(conn); }
}

async function actualizar(data) {
  const conn = await getConnection();
  try {
    await conn.execute(
      `BEGIN ${PKG}.ACTUALIZAR(:p_emp_id, :p_depto_id, :p_cargo_id, :p_rol_empleado_id, :p_nombres, :p_apellidos, :p_email, :p_telefono, :p_fecha_ingreso, :p_salario_base, :p_estado); END;`,
      {
        p_emp_id: data.emp_id,
        p_depto_id: data.depto_id,
        p_cargo_id: data.cargo_id,
        p_rol_empleado_id: data.rol_empleado_id,
        p_nombres: data.nombres,
        p_apellidos: data.apellidos,
        p_email: data.email,
        p_telefono: data.telefono,
        p_fecha_ingreso: new Date(data.fecha_ingreso),
        p_salario_base: data.salario_base,
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
      `BEGIN ${PKG}.ELIMINAR(:p_emp_id); END;`,
      { p_emp_id: id }
    );
    await conn.commit();
  } finally { await closeConn(conn); }
}

async function obtener(id) {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.OBTENER_POR_ID(:p_emp_id, :p_resultado); END;`,
      {
        p_emp_id: id,
        p_resultado: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
      }
    );
    const rows = await readCursor(result.outBinds.p_resultado);
    return rows[0] || null;
  } finally { await closeConn(conn); }
}

async function listar() {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `BEGIN ${PKG}.LISTAR(:p_resultado); END;`,
      { p_resultado: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
    );
    return await readCursor(result.outBinds.p_resultado);
  } finally { await closeConn(conn); }
}

module.exports = { insertar, actualizar, eliminar, obtener, listar };
