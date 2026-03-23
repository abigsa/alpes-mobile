const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
require("dotenv").config();

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

// Rutas
// app.use("/api/categorias", require("./routes/categoria.routes"));

app.get("/", (req, res) => {
  res.json({ mensaje: "Backend Alpes Mobile funcionando" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});

module.exports = app;
