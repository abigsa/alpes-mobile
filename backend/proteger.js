const fs = require('fs');
const path = require('path');

const ROUTES_DIR = path.join(__dirname, 'src/routes');
const BACKUP_DIR = path.join(__dirname, 'src/routes/backups');

if (!fs.existsSync(BACKUP_DIR)) {
  fs.mkdirSync(BACKUP_DIR, { recursive: true });
  console.log(`✅ Carpeta de backups creada`);
}

const RUTAS_PUBLICAS = ['/login', '/registro', '/refresh', '/logout'];

// ⚠️ ARCHIVOS QUE NO DEBEN SER MODIFICADOS
const ARCHIVOS_IGNORAR = [
  'metodo_pago.routes.js', // GET / DEBE ser público
  'autenticacion.routes.js', // Ya protegido manualmente
];

const archivos = fs.readdirSync(ROUTES_DIR)
  .filter(f => f.endsWith('.routes.js'))
  .filter(f => !ARCHIVOS_IGNORAR.includes(f)); // Ignorar archivos

console.log(`\n🔐 Protegiendo ${archivos.length} archivos de rutas...\n`);
console.log(`⚠️ Ignorando: ${ARCHIVOS_IGNORAR.join(', ')}\n`);

archivos.forEach((archivo) => {
  const rutaCompleta = path.join(ROUTES_DIR, archivo);
  let contenido = fs.readFileSync(rutaCompleta, 'utf8');

  const backupPath = path.join(BACKUP_DIR, archivo);
  fs.writeFileSync(backupPath, contenido);

  const tieneImport = contenido.includes('authenticateToken');

  if (!tieneImport) {
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

  const lineas = contenido.split('\n');
  const lineasActualizadas = lineas.map(linea => {
    if (!linea.includes('router.')) {
      return linea;
    }

    if (linea.includes('authenticateToken')) {
      return linea;
    }

    if (linea.includes('require(') || linea.includes('module.exports')) {
      return linea;
    }

    const esPublica = RUTAS_PUBLICAS.some(rp => linea.includes(`"${rp}"`) || linea.includes(`'${rp}'`));
    if (esPublica) {
      return linea;
    }

    if (linea.includes('router.get(') || linea.includes('router.post(') || 
        linea.includes('router.put(') || linea.includes('router.delete(') ||
        linea.includes('router.patch(')) {
      
      return linea.replace(', ctrl', ', authenticateToken, ctrl');
    }

    return linea;
  });

  const contenidoActualizado = lineasActualizadas.join('\n');
  fs.writeFileSync(rutaCompleta, contenidoActualizado);

  console.log(`✅ ${archivo}`);
});

console.log(`\n✅ ¡LISTO! ${archivos.length} rutas protegidas`);
console.log(`📦 Backups en: src/routes/backups/`);
console.log(`⚠️ archivos ignorados: ${ARCHIVOS_IGNORAR.join(', ')}\n`);
