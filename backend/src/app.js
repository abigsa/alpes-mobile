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
// CORS - Flutter móvil no envía header "origin"
// ============================================
const corsOptions = {
  origin: (origin, callback) => {
    if (process.env.NODE_ENV === "development") {
      return callback(null, true);
    }
    const allowedOrigins = [
      "http://localhost:3000",
      "http://localhost:8080",
      "https://app.alpes.com",
      "https://admin.alpes.com",
      "https://alpes.com",
    ];
    if (!origin || allowedOrigins.includes(origin)) {
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
// HPP
// ============================================
app.use(hpp());

// ============================================
// RATE LIMITING
// ============================================
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: "Demasiadas solicitudes, intenta después",
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: "Demasiados intentos de login, intenta después de 15 minutos",
  skipSuccessfulRequests: true,
});

app.use("/api/", generalLimiter);

// ============================================
// LOGGING
// ============================================
app.use(morgan("dev"));

// ============================================
// RUTAS PÚBLICAS
// ============================================
app.use("/api/autenticacion", authLimiter, require("./routes/autenticacion.routes"));
app.use("/api/productos",    require("./routes/producto.routes"));
app.use("/api/categorias",   require("./routes/categoria.routes"));
app.use("/api/promociones",  require("./routes/promocion.routes"));
app.use("/api/faqs",         require("./routes/faq.routes"));
app.use("/api/metodos-pago", require("./routes/metodo_pago.routes"));

app.get("/", (req, res) => res.json({ mensaje: "Backend Alpes Mobile ✅", version: "2.0.0" }));

// ============================================
// RUTAS PROTEGIDAS
// ============================================
const { authenticateToken } = require("./middleware/auth.middleware");

app.use("/api/usuarios",               authenticateToken, require("./routes/usuario.routes"));
app.use("/api/upload",                 authenticateToken, require("./routes/upload.routes"));
app.use("/api/clientes",               authenticateToken, require("./routes/cliente.routes"));
app.use("/api/carritos",               authenticateToken, require("./routes/carrito.routes"));
app.use("/api/carritos-detalle",       authenticateToken, require("./routes/carrito_detalle.routes"));
app.use("/api/ordenes-venta",          authenticateToken, require("./routes/orden_venta.routes"));
app.use("/api/ordenes-venta-detalle",  authenticateToken, require("./routes/orden_venta_detalle.routes"));
app.use("/api/listas-deseos",          authenticateToken, require("./routes/lista_deseos.routes"));
app.use("/api/resenas-comentarios",    authenticateToken, require("./routes/resena_comentario.routes"));
app.use("/api/pagos",                  authenticateToken, require("./routes/pago.routes"));
app.use("/api/envios",                 authenticateToken, require("./routes/envio.routes"));
app.use("/api/estados-envio",          authenticateToken, require("./routes/estado_envio.routes"));
app.use("/api/seguimiento-envio",      authenticateToken, require("./routes/seguimiento_envio.routes"));
app.use("/api/facturas",               authenticateToken, require("./routes/factura.routes"));
app.use("/api/facturas-detalle",       authenticateToken, require("./routes/factura_detalle.routes"));
app.use("/api/cupones",                authenticateToken, require("./routes/cupon.routes"));
app.use("/api/tarjetas-cliente",       authenticateToken, require("./routes/tarjetacliente.routes"));
app.use("/api/historial-compra",       authenticateToken, require("./routes/historial_compra.routes"));
app.use("/api/precios-historico",      authenticateToken, require("./routes/precio_historico.routes"));
app.use("/api/preferencias-cliente",   authenticateToken, require("./routes/preferencia_cliente.routes"));
app.use("/api/devoluciones",           authenticateToken, require("./routes/devolucion.routes"));
app.use("/api/cuotas-pago",            authenticateToken, require("./routes/cuotas_pago.routes"));
app.use("/api/condiciones-pago",       authenticateToken, require("./routes/condicion_pago.routes"));

app.use("/api/empleados",              authenticateToken, require("./routes/empleado.routes"));
app.use("/api/departamentos",          authenticateToken, require("./routes/departamento.routes"));
app.use("/api/cargos",                 authenticateToken, require("./routes/cargo.routes"));
app.use("/api/roles",                  authenticateToken, require("./routes/rol.routes"));
app.use("/api/permisos",               authenticateToken, require("./routes/permiso.routes"));
app.use("/api/roles-permiso",          authenticateToken, require("./routes/rol_permiso.routes"));
app.use("/api/roles-empleado",         authenticateToken, require("./routes/rol_empleado.routes"));
app.use("/api/nominas",                authenticateToken, require("./routes/nomina.routes"));
app.use("/api/nominas-detalle",        authenticateToken, require("./routes/nomina_detalle.routes"));
app.use("/api/evaluaciones",           authenticateToken, require("./routes/evaluacion.routes"));
app.use("/api/incidentes-laborales",   authenticateToken, require("./routes/incidente_laboral.routes"));
app.use("/api/historial-laboral",      authenticateToken, require("./routes/historial_laboral.routes"));
app.use("/api/expedientes-empleado",   authenticateToken, require("./routes/expediente_empleado.routes"));

app.use("/api/proveedores",            authenticateToken, require("./routes/proveedor.routes"));
app.use("/api/ordenes-compra",         authenticateToken, require("./routes/orden_compra.routes"));
app.use("/api/ordenes-compra-detalle", authenticateToken, require("./routes/orden_compra_detalle.routes"));
app.use("/api/recepciones-material",   authenticateToken, require("./routes/recepcion_material.routes"));
app.use("/api/contratos-proveedor",    authenticateToken, require("./routes/contrato_proveedor.routes"));
app.use("/api/expedientes-proveedor",  authenticateToken, require("./routes/expediente_proveedor.routes"));
app.use("/api/cuentas-pagar-proveedor",authenticateToken, require("./routes/cuenta_pagar_proveedor.routes"));
app.use("/api/pagos-proveedor",        authenticateToken, require("./routes/pago_proveedor.routes"));

app.use("/api/inventario-producto",      authenticateToken, require("./routes/inventario_producto.routes"));
app.use("/api/inventario-materia-prima", authenticateToken, require("./routes/inventario_materia_prima.routes"));
app.use("/api/materias-primas",          authenticateToken, require("./routes/materia_prima.routes"));
app.use("/api/movimientos-inventario",   authenticateToken, require("./routes/movimiento_inventario.routes"));
app.use("/api/movimientos-materia-prima",authenticateToken, require("./routes/movimiento_materia_prima.routes"));
app.use("/api/ordenes-produccion",       authenticateToken, require("./routes/orden_produccion.routes"));
app.use("/api/ordenes-produccion-tareas",authenticateToken, require("./routes/orden_produccion_tarea.routes"));
app.use("/api/planes-produccion",        authenticateToken, require("./routes/plan_produccion.routes"));
app.use("/api/estados-produccion",       authenticateToken, require("./routes/estado_produccion.routes"));
app.use("/api/consumos-materia-prima",   authenticateToken, require("./routes/consumo_materia_prima.routes"));
app.use("/api/produccion-resultados",    authenticateToken, require("./routes/produccion_resultados.routes"));
app.use("/api/listas-materiales",        authenticateToken, require("./routes/lista_materiales.routes"));
app.use("/api/listas-materiales-detalle",authenticateToken, require("./routes/lista_materiales_detalle.routes"));
app.use("/api/control-calidad",          authenticateToken, require("./routes/control_calidad.routes"));
app.use("/api/abastecimientos",          authenticateToken, require("./routes/abastecimiento.routes"));

app.use("/api/herramientas",               authenticateToken, require("./routes/herramienta.routes"));
app.use("/api/mantenimiento-herramientas", authenticateToken, require("./routes/mantenimiento_herramienta.routes"));
app.use("/api/vehiculos",                  authenticateToken, require("./routes/vehiculo.routes"));
app.use("/api/rutas-entrega",              authenticateToken, require("./routes/ruta_entrega.routes"));

app.use("/api/zonas-envio",          authenticateToken, require("./routes/zona_envio.routes"));
app.use("/api/tarifas-envio",        authenticateToken, require("./routes/tarifa_envio.routes"));
app.use("/api/tipos-entrega",        authenticateToken, require("./routes/tipo_entrega.routes"));
app.use("/api/politicas-envio",      authenticateToken, require("./routes/politica_envio.routes"));
app.use("/api/reglas-envio-gratis",  authenticateToken, require("./routes/regla_envio_gratis.routes"));
app.use("/api/estados-orden",        authenticateToken, require("./routes/estado_orden.routes"));
app.use("/api/estados-orden-compra", authenticateToken, require("./routes/estado_orden_compra.routes"));

app.use("/api/campanas-marketing",   authenticateToken, require("./routes/campana_marketing.routes"));
app.use("/api/tipos-promocion",      authenticateToken, require("./routes/tipo_promocion.routes"));
app.use("/api/promociones-producto", authenticateToken, require("./routes/promocion_producto.routes"));
app.use("/api/reglas-promocion",     authenticateToken, require("./routes/regla_promocion.routes"));
app.use("/api/historial-promocion",  authenticateToken, require("./routes/historial_promocion.routes"));

app.use("/api/sesiones",        authenticateToken, require("./routes/sesion.routes"));
app.use("/api/unidades-medida", authenticateToken, require("./routes/unidad_medida.routes"));

// ============================================
// MANEJO DE ERRORES
// ============================================
app.use((req, res) => res.status(404).json({ error: "No encontrado" }));
app.use((err, req, res, next) => {
  console.error("❌ Error global:", err);
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
      console.log(`🚀 Servidor en puerto ${PORT}`);
      console.log(`🌍 NODE_ENV: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error("❌ Error inicializando servidor:", error);
    process.exit(1);
  }
}

startServer();

module.exports = app;