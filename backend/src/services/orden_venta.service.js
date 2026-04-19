const model = require("../models/orden_venta.model");

async function listar() { return await model.listar(); }
async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Orden_Venta no encontrado/a" };
  return row;
}
async function buscar(c,v){return await model.buscar(c,v);}
async function crear(data) {
  const id = await model.insertar(data);
  return { orden_venta_id: id, ...data };
}
async function actualizar(id, data) {
  await obtener(id);
  await model.actualizar({ orden_venta_id: id, ...data });
}
async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}
async function actualizarEstado(id, estadoOrdenId, observaciones) {
  await model.actualizarEstado(id, estadoOrdenId, observaciones);
}
module.exports = { listar, obtener, crear, actualizar, actualizarEstado, eliminar, buscar };
