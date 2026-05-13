const jwt = require("jsonwebtoken");
const bcryptjs = require("bcryptjs");
const usuarioModel = require("../models/usuario.model");
const { JWT_SECRET, JWT_REFRESH_SECRET, JWT_EXPIRATION, JWT_REFRESH_EXPIRATION } = require("../config/jwt.config");

/**
 * Registrar nuevo usuario - CON BCRYPT
 */
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

  // ✅ HASH CON BCRYPT
  const passwordHash = await bcryptjs.hash(data.contrasena, 10);
  console.log(`🔐 Contraseña hasheada para ${data.email}`);

  const usuarioId = await usuarioModel.insertar({
    ...data,
    contrasena: passwordHash, // Guardar hash, no contraseña plana
  });

  const usuario = await usuarioModel.obtener(usuarioId);
  const tokens = generarTokens(usuario);

  return {
    usuarioId: usuario.USU_ID,
    cli_id:    usuario.CLI_ID    ?? null,
    emp_id:    usuario.EMP_ID    ?? null,
    rol_id:    usuario.ROL_ID    ?? null,
    nombre:    usuario.NOMBRE,
    email:     usuario.EMAIL,
    rol:       usuario.ROL_NOMBRE,
    ...tokens,
  };
}

/**
 * Login - ⚠️ COMPARACIÓN SIMPLE (TEMPORAL)
 * TODO: Cambiar a bcryptjs.compare() cuando todas las contraseñas estén hasheadas
 */
async function login(username, contrasena) {
  if (!username || !contrasena) {
    throw { message: "Username y contraseña son requeridos", status: 400 };
  }

  // Buscar usuario por USERNAME
  const usuario = await usuarioModel.loginDirecto(username);
  
  if (!usuario) {
    throw { message: "Username o contraseña incorrectos", status: 401 };
  }

  // ⚠️ TEMPORAL - Comparación simple (hasta hashear todas las contraseñas en BD)
  const esValida = contrasena === usuario.PASSWORD_HASH;
  
  if (!esValida) {
    throw { message: "Username o contraseña incorrectos", status: 401 };
  }

  console.log(`✅ ${username} autenticado correctamente`);

  const tokens = generarTokens(usuario);

  return {
    usuarioId: usuario.USU_ID,
    cli_id:    usuario.CLI_ID    ?? null,
    emp_id:    usuario.EMP_ID    ?? null,
    rol_id:    usuario.ROL_ID    ?? null,
    nombre:    usuario.NOMBRE,
    email:     usuario.EMAIL,
    rol:       usuario.ROL_NOMBRE,
    ...tokens,
  };
}

/**
 * Refresh token
 */
async function refreshToken(refreshToken) {
  if (!refreshToken) {
    throw { message: "Refresh token requerido", status: 400 };
  }

  try {
    const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    const usuario = await usuarioModel.obtener(decoded.usuarioId);
    
    if (!usuario) {
      throw { message: "Usuario no encontrado", status: 404 };
    }

    const tokens = generarTokens(usuario);

    return {
      usuarioId: usuario.USU_ID,
      cli_id:    usuario.CLI_ID    ?? null,
      emp_id:    usuario.EMP_ID    ?? null,
      rol_id:    usuario.ROL_ID    ?? null,
      nombre:    usuario.NOMBRE,
      email:     usuario.EMAIL,
      rol:       usuario.ROL_NOMBRE,
      ...tokens,
    };
  } catch (error) {
    throw { message: "Refresh token inválido o expirado", status: 401 };
  }
}

/**
 * Generar JWT tokens
 */
function generarTokens(usuario) {
  const payload = {
    usuarioId: usuario.USU_ID,
    email: usuario.EMAIL,
    nombre: usuario.NOMBRE,
    rol: usuario.ROL_NOMBRE,
  };

  const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRATION });
  const refreshToken = jwt.sign({ usuarioId: usuario.USU_ID }, JWT_REFRESH_SECRET, { expiresIn: JWT_REFRESH_EXPIRATION });

  return { accessToken, refreshToken };
}

/**
 * Cambiar contraseña - CON BCRYPT
 */
async function cambiarContrasena(usuarioId, contrasenaAnterior, contrasenaNueva) {
  if (!contrasenaAnterior || !contrasenaNueva) {
    throw { message: "Contraseña anterior y nueva son requeridas", status: 400 };
  }

  if (contrasenaNueva.length < 8) {
    throw { message: "La nueva contraseña debe tener al menos 8 caracteres", status: 400 };
  }

  const usuario = await usuarioModel.obtener(usuarioId);
  if (!usuario) {
    throw { message: "Usuario no encontrado", status: 404 };
  }

  // ⚠️ TEMPORAL - Comparación simple con contraseña anterior
  const esValida = contrasenaAnterior === usuario.PASSWORD_HASH;
  
  if (!esValida) {
    throw { message: "Contraseña anterior incorrecta", status: 401 };
  }

  // ✅ Hash de nueva contraseña con BCRYPT
  const newHash = await bcryptjs.hash(contrasenaNueva, 10);
  
  return await usuarioModel.cambiarContrasena(usuarioId, newHash);
}

module.exports = { registro, login, refreshToken, generarTokens, cambiarContrasena };
