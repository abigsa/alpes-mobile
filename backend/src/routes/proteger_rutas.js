/**
 * SCRIPT PARA PROTEGER TODAS LAS RUTAS CON authenticateToken
 * Ejecutar: node proteger_rutas.js
 */

const fs = require('fs');
const path = require('path');

const ROUTES_DIR = path.join(__dirname, 'src/routes');
const BACKUP_DIR = path.join(__dirname, 'src/routes/backups');

// Crear carpeta de backups
if (!fs.existsSync(BACKUP_DIR)) {
  fs.mkdirSync(BACKUP_DIR, { recursive: true });
  console.log(`✅ Carpeta de backups creada`);
}

// Rutas públicas que NO deben ser protegidas
const RUTAS_PUBLICAS = [
  '/login',
  '/registro',
  '/refresh',
  '/logout',
];

// Leer todos los archivos .routes.js
const archivos = fs.readdirSync(ROUTES_DIR).filter(f => f.endsWith('.routes.js'));

console.log(`\n🔐 Protegiendo ${archivos.length} archivos de rutas...\n`);

archivos.forEach((archivo) => {
  const rutaCompleta = path.join(ROUTES_DIR, archivo);
  let contenido = fs.readFileSync(rutaCompleta, 'utf8');

  // Hacer backup
  const backupPath = path.join(BACKUP_DIR, archivo);
  fs.writeFileSync(backupPath, contenido);

  // Verificar si ya tiene authenticateToken importado
  const tieneImport = contenido.includes('authenticateToken');

  // Si no lo tiene, agregar el import
  if (!tieneImport) {
    // Agregar después del último require
    const lineas = contenido.split('\n');
    let ultimaLineaRequire = 0;

    for (let i = 0; i < lineas.length; i++) {
      if (lineas[i].includes('require(') && !lineas[i].includes('module.exports')) {
        ultimaLineaRequire = i;
      }
    }

    lineas.splice(ultimaLineaRequire + 1, 0, "const { authenticateToken } = require('../middleware/auth.middleware');");
    contenido = lineas.join('\n');
  }

  // Procesar línea por línea
  const lineas = contenido.split('\n');
  const lineasActualizadas = lineas.map(linea => {
    // Ignorar líneas que no son rutas
    if (!linea.includes('router.')) {
      return linea;
    }

    // Ignorar líneas que ya tienen authenticateToken
    if (linea.includes('authenticateToken')) {
      return linea;
    }

    // Ignorar require y module.exports
    if (linea.includes('require(') || linea.includes('module.exports')) {
      return linea;
    }

    // Ignorar rutas públicas
    const esPublica = RUTAS_PUBLICAS.some(rp => linea.includes(`"${rp}"`) || linea.includes(`'${rp}'`));
    if (esPublica) {
      return linea;
    }

    // Agregar authenticateToken antes del ctrl
    // De: router.get("/", ctrl.listar);
    // A:  router.get("/", authenticateToken, ctrl.listar);
    if (linea.includes('router.get(') || linea.includes('router.post(') || 
        linea.includes('router.put(') || linea.includes('router.delete(') ||
        linea.includes('router.patch(')) {
      
      // Buscar ", ctrl" y insertar "authenticateToken, " antes
      return linea.replace(', ctrl', ', authenticateToken, ctrl');
    }

    return linea;
  });

  // Escribir archivo actualizado
  const contenidoActualizado = lineasActualizadas.join('\n');
  fs.writeFileSync(rutaCompleta, contenidoActualizado);

  console.log(`✅ ${archivo}`);
});

console.log(`\n✅ ¡LISTO! ${archivos.length} rutas protegidas`);
console.log(`📦 Backups en: src/routes/backups/`);
console.log(`\n🔍 Próximos pasos:`);
console.log(`1. Revisa un archivo para verificar`);
console.log(`2. npm run dev`);
console.log(`3. Prueba con un token válido\n`);
