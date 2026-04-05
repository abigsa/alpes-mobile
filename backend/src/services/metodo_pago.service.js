const model = require("../models/metodo_pago.model");

async function listar() { return await model.listar(); }
async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Metodo_Pago no encontrado/a" };
  return row;
}
async function buscar(c,v){return await model.buscar(c,v);}
async function crear(data) {
  const id = await model.insertar(data);
  return { metodo_pago_id: id, ...data };
}
async function actualizar(id, data) {
  await obtener(id);
  await model.actualizar({ metodo_pago_id: id, ...data });
}
async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}
module.exports = { listar, obtener, crear, actualizar, eliminar, buscar };
