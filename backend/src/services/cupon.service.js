const model = require("../models/cupon.model");

function formatFecha(fecha) {
  if (!fecha) return null;
  try {
    let dt;
    if (fecha instanceof Date) {
      dt = fecha;
    } else if (typeof fecha === 'number') {
      dt = new Date(fecha);
    } else if (typeof fecha === 'string') {
      dt = new Date(fecha);
    } else {
      return null;
    }
    return dt.toISOString().split('T')[0]; // YYYY-MM-DD
  } catch (e) {
    return null;
  }
}

async function listar() { 
  const rows = await model.listar();
  return rows.map(row => ({
    ...row,
    VIGENCIA_INICIO: formatFecha(row.VIGENCIA_INICIO),
    VIGENCIA_FIN: formatFecha(row.VIGENCIA_FIN)
  }));
}

async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Cupon no encontrado/a" };
  return {
    ...row,
    VIGENCIA_INICIO: formatFecha(row.VIGENCIA_INICIO),
    VIGENCIA_FIN: formatFecha(row.VIGENCIA_FIN)
  };
}

async function buscar(c,v){return await model.buscar(c,v);}

async function crear(data) {
  const id = await model.insertar(data);
  return { cupon_id: id, ...data };
}

async function actualizar(id, data) {
  await obtener(id);
  await model.actualizar({ cupon_id: id, ...data });
}

async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}

async function validarCupon(codigo) {
  // Listar todos y filtrar en memoria
  const cupones = await model.listar();
  const cupon = cupones.find(c => c.CODIGO === codigo.toUpperCase());
  
  if (!cupon) throw { status: 404, message: "Cupón no encontrado" };
  
  // Verificar que esté activo
  const hoy = new Date();
  const vigenciaInicio = new Date(cupon.VIGENCIA_INICIO);
  const vigenciaFin = new Date(cupon.VIGENCIA_FIN);
  
  if (hoy < vigenciaInicio || hoy > vigenciaFin) {
    throw { status: 400, message: "Cupón expirado" };
  }
  
  // Verificar límite de uso total
  const usosRestantes = (cupon.LIMITE_USO_TOTAL || 0) - (cupon.USOS_ACTUALES || 0);
  if (usosRestantes <= 0) {
    throw { status: 400, message: "Cupón sin usos disponibles" };
  }
  
  return {
    cupon_id: cupon.CUPON_ID,
    codigo: cupon.CODIGO,
    descripcion: cupon.DESCRIPCION,
    vigencia_inicio: formatFecha(cupon.VIGENCIA_INICIO),
    vigencia_fin: formatFecha(cupon.VIGENCIA_FIN),
    limite_uso_total: cupon.LIMITE_USO_TOTAL,
    limite_uso_por_cliente: cupon.LIMITE_USO_POR_CLIENTE,
    usos_actuales: cupon.USOS_ACTUALES,
  };
}

module.exports = { listar, obtener, crear, actualizar, eliminar, buscar, validarCupon };