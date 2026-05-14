const jwt        = require("jsonwebtoken");
const bcryptjs   = require("bcryptjs");
const usuarioModel = require("../models/usuario.model");
const clienteModel = require("../models/cliente.model"); // ✅ FIX 4: importar
const { JWT_SECRET, JWT_REFRESH_SECRET, JWT_EXPIRATION, JWT_REFRESH_EXPIRATION } = require("../config/jwt.config");

/**
 * ✅ FIX 4 — registro()
 * Ahora crea un registro en CLIENTE antes de insertar el usuario,
 * y asigna el CLI_ID obtenido al nuevo usuario.
 * Esto permite que el perfil muestre el nombre correcto y que
 * favoritos/reseñas funcionen con el CLI_ID desde el primer login.
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

  // ✅ Hash de contraseña
  const passwordHash = await bcryptjs.hash(data.contrasena, 10);
  console.log(`🔐 Contraseña hasheada para ${data.email}`);

  // ✅ FIX 4: Crear cliente primero para obtener CLI_ID
  let cliId = null;
  try {
    const nombres   = data.nombres   || (data.nombre.includes(' ')
                        ? data.nombre.split(' ').slice(0, -1).join(' ')
                        : data.nombre);
    const apellidos = data.apellidos || (data.nombre.includes(' ')
                        ? data.nombre.split(' ').slice(-1).join(' ')
                        : '');

    cliId = await clienteModel.insertar({
      tipo_documento: 'DPI',
      num_documento:  null,
      nit:            null,
      nombres:        nombres,
      apellidos:      apellidos,
      email:          data.email,
      tel_residencia: null,
      tel_celular:    data.telefono || null,
      direccion:      null,
      ciudad:         null,
      departamento:   null,
      pais:           'Guatemala',
      profesion:      null,
    });

    console.log(`✅ Cliente creado con CLI_ID=${cliId} para ${data.email}`);
  } catch (clienteErr) {
    // Si el SP de CLIENTE requiere campos obligatorios, ajusta los defaults arriba.
    // No bloqueamos el registro: el usuario se crea sin CLI_ID en último caso.
    console.error("⚠️  No se pudo crear el cliente:", clienteErr.message);
  }

  // ✅ Insertar usuario con el CLI_ID obtenido
  const usuarioId = await usuarioModel.insertar({
    username:        data.username,
    password_hash:   passwordHash,
    email:           data.email,
    telefono:        data.telefono || null,
    rol_id:          data.rol_id || 29,  // 29 = rol CLIENTE por defecto
    cli_id:          cliId,              // ← puede ser null si falló la creación del cliente
    emp_id:          null,
    ultimo_login_at: null,
    bloqueado_hasta: null,
    estado:          data.estado || 'ACTIVO',
  });

  const usuario = await usuarioModel.obtener(usuarioId);
  const tokens  = generarTokens(usuario);

  return {
    usuarioId: usuario.USU_ID,
    cli_id:    usuario.CLI_ID  ?? null,
    emp_id:    usuario.EMP_ID  ?? null,
    rol_id:    usuario.ROL_ID  ?? null,
    nombre:    usuario.NOMBRE,
    email:     usuario.EMAIL,
    rol:       usuario.ROL_NOMBRE,
    ...tokens,
  };
}

/**
 * Login — comparación simple (temporal hasta hashear BD existente)
 * TODO: cambiar a bcryptjs.compare() cuando todas las contraseñas estén hasheadas
 */
async function login(username, contrasena) {
  if (!username || !contrasena) {
    throw { message: "Username y contraseña son requeridos", status: 400 };
  }

  const usuario = await usuarioModel.loginDirecto(username);

  if (!usuario) {
    throw { message: "Username o contraseña incorrectos", status: 401 };
  }

  // ⚠️ TEMPORAL: comparación simple
  // Cuando todas las contraseñas estén hasheadas, reemplaza por:
  // const esValida = await bcryptjs.compare(contrasena, usuario.PASSWORD_HASH);
  const esValida = contrasena === usuario.PASSWORD_HASH;

  if (!esValida) {
    throw { message: "Username o contraseña incorrectos", status: 401 };
  }

  console.log(`✅ ${username} autenticado correctamente`);

  const tokens = generarTokens(usuario);

  return {
    usuarioId: usuario.USU_ID,
    cli_id:    usuario.CLI_ID  ?? null,
    emp_id:    usuario.EMP_ID  ?? null,
    rol_id:    usuario.ROL_ID  ?? null,
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
    if (!usuario) throw { message: "Usuario no encontrado", status: 404 };
    const tokens = generarTokens(usuario);
    return {
      usuarioId: usuario.USU_ID,
      cli_id:    usuario.CLI_ID  ?? null,
      emp_id:    usuario.EMP_ID  ?? null,
      rol_id:    usuario.ROL_ID  ?? null,
      nombre:    usuario.NOMBRE,
      email:     usuario.EMAIL,
      rol:       usuario.ROL_NOMBRE,
      ...tokens,
    };
  } catch {
    throw { message: "Refresh token inválido o expirado", status: 401 };
  }
}

/**
 * Generar JWT tokens
 */
function generarTokens(usuario) {
  const payload = {
    usuarioId: usuario.USU_ID,
    email:     usuario.EMAIL,
    nombre:    usuario.NOMBRE,
    rol:       usuario.ROL_NOMBRE,
  };
  const accessToken  = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRATION });
  const refreshTok   = jwt.sign({ usuarioId: usuario.USU_ID }, JWT_REFRESH_SECRET, { expiresIn: JWT_REFRESH_EXPIRATION });
  return { accessToken, refreshToken: refreshTok };
}

/**
 * Cambiar contraseña (con bcrypt)
 */
async function cambiarContrasena(usuarioId, contrasenaAnterior, contrasenaNueva) {
  if (!contrasenaAnterior || !contrasenaNueva) {
    throw { message: "Contraseña anterior y nueva son requeridas", status: 400 };
  }
  if (contrasenaNueva.length < 8) {
    throw { message: "La nueva contraseña debe tener al menos 8 caracteres", status: 400 };
  }
  const usuario = await usuarioModel.obtener(usuarioId);
  if (!usuario) throw { message: "Usuario no encontrado", status: 404 };

  const esValida = contrasenaAnterior === usuario.PASSWORD_HASH;
  if (!esValida) throw { message: "Contraseña anterior incorrecta", status: 401 };

  const newHash = await bcryptjs.hash(contrasenaNueva, 10);
  return await usuarioModel.cambiarContrasena(usuarioId, newHash);
}

module.exports = { registro, login, refreshToken, generarTokens, cambiarContrasena };
