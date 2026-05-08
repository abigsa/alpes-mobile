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

async function initPool() {
  await oracledb.createPool(dbConfig);
  console.log("✅ Pool Oracle principal iniciado");

  if (process.env.DB_CONNECT_STRING_STANDBY) {
    await oracledb.createPool(replicaConfig);
    console.log("✅ Pool Oracle réplica iniciado");
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