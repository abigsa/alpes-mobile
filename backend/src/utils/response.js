const ok = (res, data, mensaje="OK", status=200) =>
  res.status(status).json({ ok:true, mensaje, data });
const error = (res, mensaje="Error", status=500) =>
  res.status(status).json({ ok:false, mensaje });
module.exports = { ok, error };
