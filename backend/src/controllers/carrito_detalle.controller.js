const service = require("../services/carrito_detalle.service");
const {ok,error} = require("../utils/response");
const w = fn => async(req,res) => { try { await fn(req,res); } catch(e){error(res,e.message,e.status||500);} };
module.exports = {
  listar:    w(async(req,res)=>ok(res,await service.listar())),
  obtener:   w(async(req,res)=>ok(res,await service.obtener(req.params.id))),
  crear:     w(async(req,res)=>ok(res,await service.crear(req.body),"Carrito_Detalle creado/a",201)),
  actualizar:w(async(req,res)=>{await service.actualizar(req.params.id,req.body);ok(res,null,"Carrito_Detalle actualizado/a");}),
  eliminar:  w(async(req,res)=>{await service.eliminar(req.params.id);ok(res,null,"Carrito_Detalle eliminado/a");}),
  buscar: w(async(req,res)=>{const{criterio,valor}=req.query;ok(res,await service.buscar(criterio,valor));})
};
