const model = require("../models/usuario.model");

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
  // Traer todos los usuarios y filtrar en JS
  const todos = await model.listar();
  
  const usuario = todos.find(u => 
    (u.USERNAME ?? u.username) === username
  );

  if (!usuario) {
    throw { status: 401, message: "Credenciales incorrectas" };
  }

  const passHash = usuario.PASSWORD_HASH ?? usuario.password_hash;
  if (passHash !== password) {
    throw { status: 401, message: "Credenciales incorrectas" };
  }

  const estado = usuario.ESTADO ?? usuario.estado;
  if (estado !== 'ACTIVO') {
    throw { status: 401, message: "Usuario inactivo" };
  }

  return usuario;
}

module.exports = { listar, obtener, crear, actualizar, eliminar, login };
