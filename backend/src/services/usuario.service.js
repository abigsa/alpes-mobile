const model        = require("../models/usuario.model");
const clienteModel = require("../models/cliente.model");

async function listar() { return await model.listar(); }

async function obtener(id) {
  const row = await model.obtener(id);
  if (!row) throw { status: 404, message: "Usuario no encontrado/a" };
  return row;
}

async function buscar(c, v) { return await model.buscar(c, v); }

// ─── Crea perfil de cliente y lo vincula al usuario ───────────────────────────
async function _crearYVincularCliente(usuario, nombres, apellidos) {
  const usu_id   = usuario.USU_ID   ?? usuario.usu_id;
  const email    = (usuario.EMAIL   ?? usuario.email   ?? '').toString().trim();
  const username = (usuario.USERNAME ?? usuario.username ?? '').toString().trim();

  const nombreFinal   = (nombres   || username || 'Sin nombre').toString().trim();
  const apellidoFinal = (apellidos || '-').toString().trim(); // Oracle puede rechazar string vacío

  console.log(`[cliente] Intentando crear perfil para usu_id=${usu_id}, nombres="${nombreFinal}", email="${email}"`);

  // 1. Insertar en CLIENTE
  let cli_id;
  try {
    cli_id = await clienteModel.insertar({
      nombres:        nombreFinal,
      apellidos:      apellidoFinal,
      email:          email || null,
      tipo_documento: null,
      num_documento:  null,
      nit:            null,
      tel_residencia: null,
      tel_celular:    null,
      direccion:      null,
      ciudad:         null,
      departamento:   null,
      pais:           null,
      profesion:      null,
    });
    console.log(`[cliente] Perfil creado con CLI_ID=${cli_id}`);
  } catch (err) {
    console.error(`[cliente] ERROR al insertar CLIENTE:`, err?.message ?? err);
    return null;
  }

  // 2. Vincular CLI_ID en USUARIO
  try {
    await model.actualizar({
      usu_id,
      username:        usuario.USERNAME       ?? usuario.username,
      password_hash:   usuario.PASSWORD_HASH  ?? usuario.password_hash,
      email:           email || null,
      telefono:        usuario.TELEFONO       ?? usuario.telefono       ?? null,
      rol_id:          usuario.ROL_ID         ?? usuario.rol_id,
      cli_id,
      emp_id:          usuario.EMP_ID         ?? usuario.emp_id         ?? null,
      ultimo_login_at: null,
      bloqueado_hasta: null,
      estado:          (usuario.ESTADO ?? usuario.estado ?? 'ACTIVO').toString().trim(),
    });
    console.log(`[cliente] CLI_ID=${cli_id} vinculado a USU_ID=${usu_id}`);
  } catch (err) {
    console.error(`[cliente] ERROR al vincular CLI_ID en USUARIO:`, err?.message ?? err);
    // El cliente se creó pero no se vinculó — devolvemos el cli_id igual
  }

  return cli_id;
}
// ─────────────────────────────────────────────────────────────────────────────

async function crear(data) {
  const id = await model.insertar(data);

  const nombres   = (data.nombres   ?? data.NOMBRES   ?? '').toString().trim();
  const apellidos = (data.apellidos ?? data.APELLIDOS ?? '').toString().trim();
  if (nombres) {
    const usuarioCreado = await model.obtener(id);
    if (usuarioCreado) {
      await _crearYVincularCliente(usuarioCreado, nombres, apellidos);
    }
  }

  return { usu_id: id, ...data };
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
  const usernameTrimmed = (username ?? '').toString().trim();
  const passwordTrimmed = (password ?? '').toString().trim();

  if (!usernameTrimmed || !passwordTrimmed) {
    throw { status: 400, message: "Usuario y contraseña son requeridos" };
  }

  // Buscar por SP_BUSCAR primero
  let usuario = null;
  try {
    const resultados = await model.buscar('username', usernameTrimmed);
    if (Array.isArray(resultados) && resultados.length > 0) {
      usuario = resultados.find(u =>
        (u.USERNAME ?? u.username ?? '').toLowerCase() === usernameTrimmed.toLowerCase()
      ) || null;
    }
  } catch (_) {}

  // Fallback: listado completo
  if (!usuario) {
    const todos = await model.listar();
    usuario = todos.find(u =>
      (u.USERNAME ?? u.username ?? '').toLowerCase() === usernameTrimmed.toLowerCase()
    ) || null;
  }

  if (!usuario) throw { status: 401, message: "Credenciales incorrectas" };

  const passHash = (usuario.PASSWORD_HASH ?? usuario.password_hash ?? '').toString().trim();
  if (passHash !== passwordTrimmed) throw { status: 401, message: "Credenciales incorrectas" };

  const estado = (usuario.ESTADO ?? usuario.estado ?? '').toString().trim();
  if (estado !== 'ACTIVO') throw { status: 401, message: "Usuario inactivo" };

  // Si no tiene CLI_ID, crear perfil de cliente ahora
  let cliId = usuario.CLI_ID ?? usuario.cli_id ?? null;
  if (!cliId) {
    console.log(`[login] Usuario ${usernameTrimmed} sin CLI_ID, creando perfil...`);
    cliId = await _crearYVincularCliente(usuario, '', '');
    if (cliId) {
      usuario.CLI_ID = cliId;
      usuario.cli_id = cliId;
    }
  }

  // Enriquecer con NOMBRES y APELLIDOS del cliente
  if (cliId) {
    try {
      const cliente = await clienteModel.obtener(cliId);
      if (cliente) {
        usuario.NOMBRES   = (cliente.NOMBRES   ?? cliente.nombres   ?? '').toString().trim();
        usuario.APELLIDOS = (cliente.APELLIDOS ?? cliente.apellidos ?? '').toString().trim();
        console.log(`[login] Nombre obtenido: "${usuario.NOMBRES} ${usuario.APELLIDOS}"`);
      }
    } catch (_) {}
  }

  return usuario;
}

module.exports = { listar, obtener, crear, actualizar, eliminar, login };
