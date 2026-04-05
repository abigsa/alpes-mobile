const router = require("express").Router();
const ctrl = require("../controllers/autenticacion.controller");
const { authenticateToken, authorizeRole } = require("../middleware/auth.middleware");

// Públicas
router.post("/registro", ctrl.registro);
router.post("/login", ctrl.login);
router.post("/refresh", ctrl.refreshToken);

// Protegidas
router.post("/cambiar-contrasena", authenticateToken, ctrl.cambiarContrasena);
router.get("/me", authenticateToken, ctrl.obtenerPerfil);
router.post("/logout", authenticateToken, ctrl.logout);

module.exports = router;
```

