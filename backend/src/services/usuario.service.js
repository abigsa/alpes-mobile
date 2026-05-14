const model  = require("../models/usuario.model");
const clienteModel = require("../models/cliente.model");
const jwt    = require("jsonwebtoken");
const { JWT_SECRET, JWT_EXPIRATION } = require("../config/jwt.config");

async function listar() { return await model.listar(); }

async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Usuario no encontrado/a" };
  return row;
}

async function buscar(c, v) { return await model.buscar(c, v); }

/**
 * Crear usuario - AHORA CREA CLIENTE AUTOMÁTICAMENTE
 */
async function crear(data) {
  // Validar datos requeridos
  if (!data.username || !data.email || !data.nombres) {
    throw { status: 400, message: "Username, email y nombres son requeridos" };
  }

  let cli_id = null;

  // ✅ SI ES CLIENTE, CREAR REGISTRO EN TABLA CLIENTE
  if (data.rol_id === 3 || data.rol_nombre === 'CLIENTE') {
    try {
      cli_id = await clienteModel.insertar({
        tipo_documento: data.tipo_documento || 'CEDULA',
        num_documento: data.num_documento || '',
        nit: data.nit || '',
        nombres: data.nombres,
        apellidos: data.apellidos || '',
        email: data.email,
        tel_residencia: data.tel_residencia || '',
        tel_celular: data.tel_celular || '',
        direccion: data.direccion || '',
        ciudad: data.ciudad || '',
        departamento: data.departamento || '',
        pais: data.pais || '',
        profesion: data.profesion || '',
      });
      console.log(`✅ Cliente creado automáticamente: CLI_ID=${cli_id}`);
    } catch (err) {
      console.error(`⚠️ Error creando cliente:`, err.message);
      // No fallar si no se puede crear cliente, continuar con usuario
    }
  }

  // Insertar usuario
  const usuarioData = {
    ...data,
    cli_id: cli_id, // Asignar el CLI_ID creado
  };

  const id = await model.insertar(usuarioData);
  
  console.log(`✅ Usuario creado: USU_ID=${id}, CLI_ID=${cli_id}`);

  return { 
    usu_id: id, 
    cli_id: cli_id,
    ...data 
  };
}

async function actualizar(id, data) {
  await obtener(id);
  await model.actualizar({ usu_id: id, ...data });
}

async function eliminar(id) {
  await obtener(id);
  await model.eliminar(id);
}

async function login(username, password) {
  // Query directa con JOIN a ROL — garantiza ROL_NOMBRE correcto
  const usuario = await model.loginDirecto(username);
  if (!usuario) throw { status: 401, message: "Credenciales incorrectas" };

  const passHash = usuario.PASSWORD_HASH ?? usuario.password_hash;
  if (passHash !== password) throw { status: 401, message: "Credenciales incorrectas" };

  const estado = usuario.ESTADO ?? usuario.estado;
  if (estado !== "ACTIVO") throw { status: 401, message: "Usuario inactivo" };

  const rolNombre = (usuario.ROL_NOMBRE ?? "CLIENTE").toString().toUpperCase().trim();

  // Generar JWT
  const payload = {
    usu_id:     usuario.USU_ID,
    username:   usuario.USERNAME,
    rol:        rolNombre,
    rol_id:     usuario.ROL_ID,
    cli_id:     usuario.CLI_ID,
    emp_id:     usuario.EMP_ID,
  };
  const token = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRATION });

  return {
    token,
    usuario: { ...usuario, ROL_NOMBRE: rolNombre },
  };
}

module.exports = { listar, obtener, crear, actualizar, eliminar, login, buscar };
