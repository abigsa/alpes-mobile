const tarjetaclienteservice = require('../services/tarjetaclienteservice');

function normalizarError(error) {
  if (error && error.message) {
    return error.message;
  }
  return 'Ocurrió un error interno';
}

async function crearTarjeta(req, res) {
  try {
    const {
      cliId,
      titular,
      ultimos4,
      marca,
      mesVencimiento,
      anioVencimiento,
      aliasTarjeta,
      predeterminada,
    } = req.body;

    if (!cliId || !titular || !ultimos4 || !marca || !mesVencimiento || !anioVencimiento) {
      return res.status(400).json({
        ok: false,
        message: 'Faltan campos obligatorios',
      });
    }

    const response = await tarjetaclienteservice.crearTarjeta({
      cliId,
      titular,
      ultimos4,
      marca,
      mesVencimiento,
      anioVencimiento,
      aliasTarjeta,
      predeterminada,
    });

    return res.status(201).json(response);
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: normalizarError(error),
    });
  }
}

async function listarTarjetasPorCliente(req, res) {
  try {
    const { cliId } = req.params;

    if (!cliId) {
      return res.status(400).json({
        ok: false,
        message: 'cliId es requerido',
      });
    }

    const tarjetas = await tarjetaclienteservice.obtenerTarjetasPorCliente(Number(cliId));

    return res.status(200).json({
      ok: true,
      data: tarjetas,
    });
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: normalizarError(error),
    });
  }
}

async function obtenerTarjetaPorId(req, res) {
  try {
    const { tarjetaClienteId } = req.params;

    const tarjeta = await tarjetaclienteservice.obtenerTarjetaPorId(Number(tarjetaClienteId));

    if (!tarjeta) {
      return res.status(404).json({
        ok: false,
        message: 'Tarjeta no encontrada',
      });
    }

    return res.status(200).json({
      ok: true,
      data: tarjeta,
    });
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: normalizarError(error),
    });
  }
}

async function actualizarTarjeta(req, res) {
  try {
    const { tarjetaClienteId } = req.params;
    const {
      titular,
      ultimos4,
      marca,
      mesVencimiento,
      anioVencimiento,
      aliasTarjeta,
      predeterminada,
    } = req.body;

    const response = await tarjetaclienteservice.actualizarTarjeta(Number(tarjetaClienteId), {
      titular,
      ultimos4,
      marca,
      mesVencimiento,
      anioVencimiento,
      aliasTarjeta,
      predeterminada,
    });

    return res.status(200).json(response);
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: normalizarError(error),
    });
  }
}

async function desactivarTarjeta(req, res) {
  try {
    const { tarjetaClienteId } = req.params;

    const response = await tarjetaclienteservice.desactivarTarjeta(Number(tarjetaClienteId));

    return res.status(200).json(response);
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: normalizarError(error),
    });
  }
}

async function marcarPredeterminada(req, res) {
  try {
    const { tarjetaClienteId } = req.params;
    const { cliId } = req.body;

    if (!cliId) {
      return res.status(400).json({
        ok: false,
        message: 'cliId es requerido',
      });
    }

    const response = await tarjetaclienteservice.marcarPredeterminada(
      Number(tarjetaClienteId),
      Number(cliId)
    );

    return res.status(200).json(response);
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: normalizarError(error),
    });
  }
}

module.exports = {
  crearTarjeta,
  listarTarjetasPorCliente,
  obtenerTarjetaPorId,
  actualizarTarjeta,
  desactivarTarjeta,
  marcarPredeterminada,
};