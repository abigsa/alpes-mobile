async function readCursor(cursor) {
  const rows = await cursor.getRows();
  await cursor.close();
  return rows;
}
async function closeConn(conn) {
  try { if (conn) await conn.close(); } catch(e) {}
}
module.exports = { readCursor, closeConn, toDate };

function toDate(val) {
  if (!val) return null;
  if (val instanceof Date) return isNaN(val.getTime()) ? null : val;
  const d = new Date(val);
  return isNaN(d.getTime()) ? null : d;
}
