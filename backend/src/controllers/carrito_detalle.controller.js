const service = require("../services/carrito_detalle.service");
const {ok,error} = require("../utils/response");
const w = fn => async(req,res) => { 
  try { 
    await fn(req,res); 
  } catch(e) {
    console.error(`[CARRITO_DETALLE ERROR] ${req.method} ${req.path}:`, e.message, e);
    error(res, e.message, e.status||500);
  }
};
module.exports = {
  listar:    w(async(req,res)=>ok(res,await service.listar())),
  obtener:   w(async(req,res)=>ok(res,await service.obtener(req.params.id))),
  crear:     w(async(req,res)=>{
    console.log('[CARRITO_DET] Crear detalle body:', req.body);
    const result = await service.crear(req.body);
    console.log('[CARRITO_DET] Detalle creado:', result);
    ok(res, result, "Carrito_Detalle creado/a", 201);
  }),
  actualizar:w(async(req,res)=>{await service.actualizar(req.params.id,req.body);ok(res,null,"Carrito_Detalle actualizado/a");}),
  eliminar:  w(async(req,res)=>{await service.eliminar(req.params.id);ok(res,null,"Carrito_Detalle eliminado/a");}),
  buscar:    w(async(req,res)=>{
    const{criterio,valor}=req.query;
    console.log(`[CARRITO_DET] Buscar criterio=${criterio} valor=${valor}`);
    const data = await service.buscar(criterio,valor);
    console.log('[CARRITO_DET] Resultado buscar:', JSON.stringify(data));
    ok(res,data);
  })
};
