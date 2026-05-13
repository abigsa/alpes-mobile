const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const hpp = require("hpp");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");
require("dotenv").config();

const { initPool } = require("./config/db");

const app = express();

// ============================================
// SEGURIDAD - HELMET
// ============================================
app.use(helmet());
app.disable("x-powered-by");

// ============================================
// CORS RESTRINGIDO
// ============================================
const corsOptions = {
  origin: (origin, callback) => {
    const allowedOrigins = [
      "http://localhost:3000",
      "http://localhost:8080",
      "https://app.alpes.com",
      "https://admin.alpes.com",
      "https://alpes.com"
    ];

    if (process.env.NODE_ENV === "development" && !origin) {
      return callback(null, true);
    }

    if (allowedOrigins.includes(origin) || process.env.NODE_ENV === "development") {
      callback(null, true);
    } else {
      callback(new Error("CORS no permitido"));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
};

app.use(cors(corsOptions));

// ============================================
// BODY PARSER
// ============================================
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ limit: "10mb", extended: true }));

// ============================================
// HPP - Protección
// ============================================
app.use(hpp());

// ============================================
// RATE LIMITING
// ============================================
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: "Demasiadas solicitudes, intenta después",
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: "Demasiados intentos de login, intenta después de 15 minutos",
  skipSuccessfulRequests: true,
});

app.use("/api/", generalLimiter);

// ============================================
// LOGGING
// ============================================
app.use(morgan("dev"));

// ============================================
// RUTAS PÚBLICAS (SIN AUTENTICACIÓN)
// ============================================
app.use("/api/autenticacion", authLimiter, require("./routes/autenticacion.routes"));

app.get("/", (req, res) => res.json({ 
  mensaje: "Backend Alpes Mobile ✅", 
  version: "2.0.0"
}));

// ============================================
// RUTAS PROTEGIDAS (CON AUTENTICACIÓN)
// ============================================
const { authenticateToken, authorizeRole } = require("./middleware/auth.middleware");

app.use("/api/usuarios", authenticateToken, require("./routes/usuario.routes"));
app.use("/api/upload", authenticateToken, require("./routes/upload.routes"));
app.use("/api/abastecimientos", authenticateToken, require("./routes/abastecimiento.routes"));
app.use("/api/campanas-marketing", authenticateToken, require("./routes/campana_marketing.routes"));
app.use("/api/cargos", authenticateToken, require("./routes/cargo.routes"));
app.use("/api/carritos", authenticateToken, require("./routes/carrito.routes"));
app.use("/api/carritos-detalle", authenticateToken, require("./routes/carrito_detalle.routes"));
app.use("/api/categorias", authenticateToken, require("./routes/categoria.routes"));
app.use("/api/clientes", authenticateToken, require("./routes/cliente.routes"));
app.use("/api/productos", authenticateToken, require("./routes/producto.routes"));
app.use("/api/ordenes-venta", authenticateToken, require("./routes/orden_venta.routes"));
app.use("/api/tarjetas-cliente", authenticateToken, require("./routes/tarjetacliente.routes"));

// AGREGAR EL RESTO DE RUTAS CON authenticateToken IGUAL

// ============================================
// MANEJO DE ERRORES
// ============================================
app.use((req, res) => res.status(404).json({ error: "No encontrado" }));
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Error interno del servidor" });
});

// ============================================
// INICIALIZAR SERVIDOR
// ============================================
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    await initPool();
    console.log("✅ Pool Oracle iniciado");

    app.listen(PORT, () => {
      console.log(`🚀 Servidor seguro en puerto ${PORT}`);
      console.log(`🛡️  Helmet: ACTIVADO`);
      console.log(`⏱️  Rate Limiting: ACTIVADO`);
    });
  } catch (error) {
    console.error("❌ Error inicializando servidor:", error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
