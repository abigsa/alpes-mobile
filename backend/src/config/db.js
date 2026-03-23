const oracledb = require("oracledb");

const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING,
  poolMin: 2,
  poolMax: 10,
  poolIncrement: 1,
};

async function initPool() {
  try {
    await oracledb.createPool(dbConfig);
    console.log("Pool de conexiones Oracle iniciado");
  } catch (err) {
    console.error("Error al iniciar pool Oracle:", err);
    throw err;
  }
}

async function getConnection() {
  return await oracledb.getConnection();
}

async function closePool() {
  try {
    await oracledb.getPool().close(10);
    console.log("Pool cerrado");
  } catch (err) {
    console.error("Error al cerrar pool:", err);
  }
}

module.exports = { initPool, getConnection, closePool };
