const service = require("../services/autenticacion.service");
const { ok, error } = require("../utils/response");

const w = (fn) => async (req, res) => {
  try {
    await fn(req, res);
  } catch (e) {
    error(res, e.message, e.status || 500);
  }
};

module.exports = {
  registro: w(async (req, res) => {
    const result = await service.registro(req.body);
    ok(res, result, "Usuario registrado exitosamente", 201);
  }),

  login: w(async (req, res) => {
    const { email, contrasena } = req.body;
    const result = await service.login(email, contrasena);
    ok(res, result, "Login exitoso");
  }),

  refreshToken: w(async (req, res) => {
    const { refreshToken } = req.body;
    const result = await service.refreshToken(refreshToken);
    ok(res, result, "Token renovado");
  }),

  cambiarContrasena: w(async (req, res) => {
    const { contrasenaAnterior, contrasenaNueva } = req.body;
    const usuarioId = req.user.usuarioId;
    const result = await service.cambiarContrasena(usuarioId, contrasenaAnterior, contrasenaNueva);
    ok(res, result);
  }),

  logout: w(async (req, res) => {
    ok(res, null, "Logout exitoso");
  }),

  obtenerPerfil: w(async (req, res) => {
    const usuario = req.user;
    ok(res, usuario, "Perfil obtenido");
  }),
};

