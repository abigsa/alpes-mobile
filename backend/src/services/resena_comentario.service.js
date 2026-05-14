const model = require("../models/resena_comentario.model");

async function listar() { return await model.listar(); }

async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Resena_Comentario no encontrado/a" };
  return row;
}

async function buscar(c, v) { return await model.buscar(c, v); }

async function crear(data) {
  // ✅ FIX: convertir resena_at de string ISO a objeto Date que Oracle entiende
  const dataFixed = {
    ...data,
    resena_at: data.resena_at ? new Date(data.resena_at) : new Date(),
  };
  const id = await model.insertar(dataFixed);
  return { resena_id: id, ...data };
}

async function actualizar(id, data) {
  await obtener(id);
  const dataFixed = {
    ...data,
    resena_id: id,
    resena_at: data.resena_at ? new Date(data.resena_at) : new Date(),
  };
  await model.actualizar(dataFixed);
}

async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}

module.exports = { listar, obtener, crear, actualizar, eliminar, buscar };
