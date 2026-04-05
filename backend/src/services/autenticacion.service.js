const jwt = require("jsonwebtoken");
const usuarioModel = require("../models/usuario.model");
const { JWT_SECRET, JWT_REFRESH_SECRET, JWT_EXPIRATION, JWT_REFRESH_EXPIRATION } = require("../config/jwt.config");

async function registro(data) {
  if (!data.email || !data.contrasena || !data.nombre) {
    throw { message: "Email, contraseña y nombre son requeridos", status: 400 };
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(data.email)) {
    throw { message: "Email inválido", status: 400 };
  }

  if (data.contrasena.length < 8) {
    throw { message: "La contraseña debe tener al menos 8 caracteres", status: 400 };
  }

  const usuarioExistente = await usuarioModel.obtenerPorEmail(data.email);
  if (usuarioExistente) {
    throw { message: "El email ya está registrado", status: 409 };
  }

  const usuarioId = await usuarioModel.crearUsuario(data);
  const usuario = await usuarioModel.obtenerPorId(usuarioId);
  const tokens = generarTokens(usuario);

  return {
    usuarioId: usuario.USUARIO_ID,
    nombre: usuario.NOMBRE,
    email: usuario.EMAIL,
    rol: usuario.ROL,
    ...tokens,
  };
}

async function login(email, contrasena) {
  if (!email || !contrasena) {
    throw { message: "Email y contraseña son requeridos", status: 400 };
  }

  const usuario = await usuarioModel.obtenerPorEmail(email);
  if (!usuario) {
    throw { message: "Email o contraseña incorrectos", status: 401 };
  }

  const esValida = await usuarioModel.validarContrasena(contrasena, usuario.CONTRASENA_HASH);
  if (!esValida) {
    throw { message: "Email o contraseña incorrectos", status: 401 };
  }

  const tokens = generarTokens(usuario);

  return {
    usuarioId: usuario.USUARIO_ID,
    nombre: usuario.NOMBRE,
    email: usuario.EMAIL,
    rol: usuario.ROL,
    ...tokens,
  };
}

async function refreshToken(refreshToken) {
  if (!refreshToken) {
    throw { message: "Refresh token requerido", status: 400 };
  }

  try {
    const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    const usuario = await usuarioModel.obtenerPorId(decoded.usuarioId);
    if (!usuario) {
      throw { message: "Usuario no encontrado", status: 404 };
    }

    const tokens = generarTokens(usuario);

    return {
      usuarioId: usuario.USUARIO_ID,
      nombre: usuario.NOMBRE,
      email: usuario.EMAIL,
      rol: usuario.ROL,
      ...tokens,
    };
  } catch (error) {
    throw { message: "Refresh token inválido o expirado", status: 401 };
  }
}

function generarTokens(usuario) {
  const payload = {
    usuarioId: usuario.USUARIO_ID,
    email: usuario.EMAIL,
    nombre: usuario.NOMBRE,
    rol: usuario.ROL,
  };

  const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRATION });
  const refreshToken = jwt.sign({ usuarioId: usuario.USUARIO_ID }, JWT_REFRESH_SECRET, { expiresIn: JWT_REFRESH_EXPIRATION });

  return { accessToken, refreshToken };
}

async function cambiarContrasena(usuarioId, contrasenaAnterior, contrasenaNueva) {
  if (!contrasenaAnterior || !contrasenaNueva) {
    throw { message: "Contraseña anterior y nueva son requeridas", status: 400 };
  }

  if (contrasenaNueva.length < 8) {
    throw { message: "La nueva contraseña debe tener al menos 8 caracteres", status: 400 };
  }

  return await usuarioModel.cambiarContrasena(usuarioId, contrasenaAnterior, contrasenaNueva);
}

module.exports = { registro, login, refreshToken, generarTokens, cambiarContrasena };

