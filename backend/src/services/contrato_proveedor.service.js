const model = require("../models/contrato_proveedor.model");

async function listar() { return await model.listar(); }
async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Contrato_Proveedor no encontrado/a" };
  return row;
}
async function buscar(c,v){return await model.buscar(c,v);}
async function crear(data) {
  const id = await model.insertar(data);
  return { contrato_proveedor_id: id, ...data };
}
async function actualizar(id, data) {
  await obtener(id);
  await model.actualizar({ contrato_proveedor_id: id, ...data });
}
async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}
module.exports = { listar, obtener, crear, actualizar, eliminar, buscar };
