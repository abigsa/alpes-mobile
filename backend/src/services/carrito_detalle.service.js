const model = require("../models/carrito_detalle.model");

async function listar() { return await model.listar(); }
async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Carrito_Detalle no encontrado/a" };
  return row;
}
async function buscar(c,v){return await model.buscar(c,v);}
async function crear(data) {
  const id = await model.insertar(data);
  return { carrito_det_id: id, ...data };
}
async function actualizar(id, data) {
  await model.actualizar({ carrito_det_id: id, ...data });
}
// FIX: eliminar directo sin validar con obtener primero (el SP puede fallar si ya no existe)
async function eliminar(id) {
  await model.eliminar(id);
}
module.exports = { listar, obtener, crear, actualizar, eliminar, buscar };
