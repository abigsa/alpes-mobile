/**
 * SERVICIO DE BRUTE FORCE PROTECTION
 * Bloquea usuarios tras 5 intentos fallidos durante 15 minutos
 * Retorna información de intentos restantes
 */

// En memoria (en producción usar Redis)
const intentosFallidos = new Map();
const LIMITE_INTENTOS = 5;
const TIEMPO_BLOQUEO_MS = 15 * 60 * 1000; // 15 minutos

/**
 * Registrar intento fallido y retornar info
 */
function registrarIntentoFallido(username) {
  if (!intentosFallidos.has(username)) {
    intentosFallidos.set(username, {
      intentos: 0,
      primerIntento: Date.now(),
      bloqueadoHasta: null,
    });
  }

  const registro = intentosFallidos.get(username);
  registro.intentos += 1;

  const intentosRestantes = LIMITE_INTENTOS - registro.intentos;

  console.log(`⚠️ Intento fallido para ${username}: ${registro.intentos}/${LIMITE_INTENTOS}`);
  console.log(`📊 Intentos restantes: ${Math.max(0, intentosRestantes)}`);

  // Si alcanza el límite, bloquear
  if (registro.intentos >= LIMITE_INTENTOS) {
    registro.bloqueadoHasta = Date.now() + TIEMPO_BLOQUEO_MS;
    console.log(`🚫 ${username} BLOQUEADO hasta ${new Date(registro.bloqueadoHasta).toLocaleTimeString()}`);
    
    return {
      bloqueado: true,
      intentosRestantes: 0,
      tiempoBloqueoSegundos: Math.ceil(TIEMPO_BLOQUEO_MS / 1000),
      mensaje: `Cuenta bloqueada. Demasiados intentos fallidos. Intenta de nuevo en 15 minutos.`,
    };
  }

  // Aún tiene intentos
  return {
    bloqueado: false,
    intentosRestantes: intentosRestantes,
    tiempoBloqueoSegundos: null,
    mensaje: `Te quedan ${intentosRestantes} intento${intentosRestantes !== 1 ? 's' : ''} antes de bloquear la cuenta.`,
  };
}

/**
 * Verificar si usuario está bloqueado
 */
function estasBloqueado(username) {
  if (!intentosFallidos.has(username)) {
    return { bloqueado: false };
  }

  const registro = intentosFallidos.get(username);

  // Si no está bloqueado
  if (!registro.bloqueadoHasta) {
    return { bloqueado: false };
  }

  // Si el bloqueo expiró
  if (Date.now() > registro.bloqueadoHasta) {
    console.log(`✅ Bloqueo expirado para ${username}`);
    intentosFallidos.delete(username);
    return { bloqueado: false };
  }

  // Está bloqueado
  const tiempoRestante = Math.ceil((registro.bloqueadoHasta - Date.now()) / 1000);
  console.log(`🚫 ${username} aún está bloqueado. Reintentar en ${tiempoRestante}s`);
  
  return {
    bloqueado: true,
    tiempoRestante: tiempoRestante,
    mensaje: `Cuenta bloqueada. Intenta de nuevo en ${tiempoRestante} segundo${tiempoRestante !== 1 ? 's' : ''}.`,
  };
}

/**
 * Limpiar intentos después de login exitoso
 */
function limpiarIntentos(username) {
  if (intentosFallidos.has(username)) {
    console.log(`✅ Intentos fallidos limpios para ${username}`);
    intentosFallidos.delete(username);
  }
}

/**
 * Obtener estado actual (para debug)
 */
function obtenerEstado(username) {
  if (!intentosFallidos.has(username)) {
    return {
      bloqueado: false,
      intentos: 0,
      intentosRestantes: LIMITE_INTENTOS,
    };
  }

  const registro = intentosFallidos.get(username);
  const bloqueado = estasBloqueado(username);

  return {
    bloqueado: bloqueado.bloqueado,
    intentos: registro.intentos,
    intentosRestantes: Math.max(0, LIMITE_INTENTOS - registro.intentos),
    tiempoRestante: bloqueado.tiempoRestante || null,
  };
}

module.exports = {
  registrarIntentoFallido,
  estasBloqueado,
  limpiarIntentos,
  obtenerEstado,
  LIMITE_INTENTOS,
};
