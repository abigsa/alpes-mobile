async function readCursor(cursor) {
  const rows = await cursor.getRows();
  await cursor.close();
  return rows;
}
async function closeConn(conn) {
  try { if (conn) await conn.close(); } catch(e) {}
}
module.exports = { readCursor, closeConn };
