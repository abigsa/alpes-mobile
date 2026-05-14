const service = require("../services/autenticacion.service");
const { ok, error } = require("../utils/response");

const w = (fn) => async (req, res) => {
  try {
    await fn(req, res);
  } catch (e) {
    console.error('❌ Error en controller:', e.message);
    error(res, e.message, e.status || 500);
  }
};

module.exports = {
  registro: w(async (req, res) => {
    const result = await service.registro(req.body);
    ok(res, result, "Usuario registrado exitosamente", 201);
  }),

  // ✅ LOGIN - ACEPTA USERNAME (NO EMAIL)
  login: w(async (req, res) => {
    const { username, contrasena } = req.body;
    console.log('🔐 Controller login recibido:', { username, contrasena });
    
    if (!username || !contrasena) {
      return error(res, "Username y contraseña son requeridos", 400);
    }
    
    const result = await service.login(username, contrasena);
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
