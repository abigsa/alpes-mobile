const oracledb = require("oracledb");
require("dotenv").config();
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECT_STRING,
  poolMin: 2, poolMax: 10, poolIncrement: 1,
};
async function initPool() {
  await oracledb.createPool(dbConfig);
  console.log("✅ Pool Oracle iniciado");
}
async function getConnection() { return await oracledb.getConnection(); }
module.exports = { initPool, getConnection };
