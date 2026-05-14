const oracledb = require("oracledb");
require("dotenv").config();

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;

const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING,
  poolMin: 2,
  poolMax: 10,
  poolIncrement: 1,
};

const replicaConfig = {
  user: process.env.DB_STANDBY_USER || process.env.DB_USER,
  password: process.env.DB_STANDBY_PASSWORD || process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING_STANDBY,
  poolAlias: "replica",
  poolMin: 1,
  poolMax: 10,
  poolIncrement: 1,
};

// ✅ Crear tabla PAGO si no existe
async function crearTablaPago(conn) {
  try {
    await conn.execute(`
      CREATE TABLE PAGO (
        PAGO_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        ORDEN_VENTA_ID NUMBER NOT NULL,
        METODO_PAGO_ID NUMBER NOT NULL,
        MONTO NUMBER(12,2) NOT NULL,
        ESTADO_PAGO VARCHAR2(50),
        REFERENCIA VARCHAR2(100),
        PAGO_AT TIMESTAMP,
        ESTADO VARCHAR2(10) DEFAULT 'ACTIVO',
        CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log("✅ Tabla PAGO creada exitosamente");
  } catch (err) {
    // Si ya existe, no hace nada
    if (err.errorNum === 955) {
      console.log("✅ Tabla PAGO ya existe");
    } else {
      console.error("❌ Error creando tabla PAGO:", err.message);
    }
  }
}

async function initPool() {
  await oracledb.createPool(dbConfig);
  console.log("✅ Pool Oracle principal iniciado");

  if (process.env.DB_CONNECT_STRING_STANDBY) {
    await oracledb.createPool(replicaConfig);
    console.log("✅ Pool Oracle réplica iniciado");
  }

  // ✅ Crear tabla PAGO al iniciar
  try {
    const conn = await getConnection();
    await crearTablaPago(conn);
    await conn.close();
  } catch (err) {
    console.error("❌ Error inicializando tabla PAGO:", err.message);
  }
}

async function getConnection() {
  return await oracledb.getConnection();
}

async function getReplicaConnection() {
  if (!process.env.DB_CONNECT_STRING_STANDBY) {
    return await getConnection();
  }

  return await oracledb.getConnection("replica");
}

module.exports = {
  initPool,
  getConnection,
  getReplicaConnection,
};
