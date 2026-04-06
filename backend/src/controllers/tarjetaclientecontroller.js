const model = require("../models/tarjetacliente.model");
const { ok, error } = require("../utils/response");
const w = fn => async (req, res) => {
  try { await fn(req, res); } catch (e) { error(res, e.message, e.status || 500); }
};

module.exports = {
  crearTarjeta: w(async (req, res) => {
    await model.insertar(req.body);
    ok(res, null, "Tarjeta registrada", 201);
  }),

  listarTarjetasPorCliente: w(async (req, res) => {
    const tarjetas = await model.listarPorCliente(req.params.cliId);
    ok(res, tarjetas);
  }),

  obtenerTarjetaPorId: w(async (req, res) => {
    const tarjetas = await model.listarPorCliente(req.params.tarjetaClienteId);
    const tarjeta = tarjetas.find(t =>
      (t.TARJETA_CLIENTE_ID ?? t.tarjeta_cliente_id) == req.params.tarjetaClienteId
    );
    if (!tarjeta) return error(res, "Tarjeta no encontrada", 404);
    ok(res, tarjeta);
  }),

  actualizarTarjeta: w(async (req, res) => {
    await model.actualizar(req.params.tarjetaClienteId, req.body);
    ok(res, null, "Tarjeta actualizada");
  }),

  desactivarTarjeta: w(async (req, res) => {
    await model.desactivar(req.params.tarjetaClienteId);
    ok(res, null, "Tarjeta desactivada");
  }),

  marcarPredeterminada: w(async (req, res) => {
    const { cli_id } = req.body;
    await model.marcarPredeterminada(req.params.tarjetaClienteId, cli_id);
    ok(res, null, "Tarjeta marcada como predeterminada");
  }),
};
