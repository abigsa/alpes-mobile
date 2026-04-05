const model = require("../models/historial_laboral.model");

async function listar() { return await model.listar(); }
async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Historial_Laboral no encontrado/a" };
  return row;
}
async function crear(data) {
  const id = await model.insertar(data);
  return { historial_laboral_id: id, ...data };
}
async function actualizar(id, data) {
  await obtener(id);
  await model.actualizar({ historial_laboral_id: id, ...data });
}
async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}
module.exports = { listar, obtener, crear, actualizar, eliminar };
