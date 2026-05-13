const model  = require("../models/usuario.model");
const jwt    = require("jsonwebtoken");
const { JWT_SECRET, JWT_EXPIRATION } = require("../config/jwt.config");

async function listar() { return await model.listar(); }

async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Usuario no encontrado/a" };
  return row;
}

async function buscar(c, v) { return await model.buscar(c, v); }

async function crear(data) {
  const id = await model.insertar(data);
  return { usu_id: id, ...data };
}

async function actualizar(id, data) {
  await obtener(id);
  await model.actualizar({ usu_id: id, ...data });
}

async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}

async function login(username, password) {
  // Query directa con JOIN a ROL — garantiza ROL_NOMBRE correcto
  const usuario = await model.loginDirecto(username);
  if (!usuario) throw { status: 401, message: "Credenciales incorrectas" };

  const passHash = usuario.PASSWORD_HASH ?? usuario.password_hash;
  if (passHash !== password) throw { status: 401, message: "Credenciales incorrectas" };

  const estado = usuario.ESTADO ?? usuario.estado;
  if (estado !== "ACTIVO") throw { status: 401, message: "Usuario inactivo" };

  const rolNombre = (usuario.ROL_NOMBRE ?? "CLIENTE").toString().toUpperCase().trim();

  // Generar JWT
  const payload = {
    usu_id:     usuario.USU_ID,
    username:   usuario.USERNAME,
    rol:        rolNombre,
    rol_id:     usuario.ROL_ID,
    cli_id:     usuario.CLI_ID,
    emp_id:     usuario.EMP_ID,
  };
  const token = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRATION });

  return {
    token,
    usuario: { ...usuario, ROL_NOMBRE: rolNombre },
  };
}

module.exports = { listar, obtener, crear, actualizar, eliminar, login, buscar };
