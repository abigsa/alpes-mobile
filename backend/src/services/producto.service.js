const model       = require("../models/producto.model");
const precioModel = require("../models/precio_historico.model");

// Carga todos los precios activos UNA sola vez y arma un mapa { PRODUCTO_ID -> precio }
// Usa SP_LISTAR_PRECIO_HISTORICO que ya filtra ESTADO = 'ACTIVO'
// y ordena por VIGENCIA_INICIO DESC, por lo que el primero de cada producto es el más reciente
async function _mapaPreciosActivos() {
  try {
    const registros = await precioModel.listar(); // llama SP_LISTAR_PRECIO_HISTORICO
    const hoy  = new Date();
    const mapa = new Map();

    for (const r of registros) {
      const prodId = r.PRODUCTO_ID ?? r.producto_id;
      const precio = r.PRECIO      ?? r.precio;
      const inicio = r.VIGENCIA_INICIO ?? r.vigencia_inicio;
      const fin    = r.VIGENCIA_FIN    ?? r.vigencia_fin;

      // Verificar que la vigencia incluya hoy
      const vigente = (!inicio || new Date(inicio) <= hoy) &&
                      (!fin    || new Date(fin)    >= hoy);

      // El SP ya viene ordenado DESC, así que el primer registro vigente de cada
      // producto es el más reciente — no pisamos si ya hay uno
      if (vigente && precio != null && !mapa.has(prodId)) {
        mapa.set(prodId, parseFloat(precio));
      }
    }
    return mapa;
  } catch (_) {
    return new Map();
  }
}

async function listar() {
  const [productos, mapa] = await Promise.all([model.listar(), _mapaPreciosActivos()]);
  return productos.map(p => ({
    ...p,
    PRECIO: mapa.get(p.PRODUCTO_ID ?? p.producto_id) ?? null
  }));
}

async function obtener(id) {
  const [row, mapa] = await Promise.all([model.obtener(id), _mapaPreciosActivos()]);
  if (!row) throw { status: 404, message: "Producto no encontrado/a" };
  return { ...row, PRECIO: mapa.get(row.PRODUCTO_ID ?? row.producto_id) ?? null };
}

async function buscar(c, v) {
  const [resultados, mapa] = await Promise.all([model.buscar(c, v), _mapaPreciosActivos()]);
  return resultados.map(p => ({
    ...p,
    PRECIO: mapa.get(p.PRODUCTO_ID ?? p.producto_id) ?? null
  }));
}

async function crear(data) {
  const id = await model.insertar(data);
  return { producto_id: id, ...data };
}
async function actualizar(id, data) {
  await model.obtener(id);
  await model.actualizar({ producto_id: id, ...data });
}
async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}

module.exports = { listar, obtener, crear, actualizar, eliminar, buscar };
