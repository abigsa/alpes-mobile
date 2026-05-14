const router = require("express").Router();
const ctrl = require("../controllers/cupon.controller");
const { authenticateToken } = require('../middleware/auth.middleware');

router.get("/", authenticateToken, ctrl.listar);
router.get("/buscar", authenticateToken, ctrl.buscar);
router.get("/:id", authenticateToken, ctrl.obtener);
router.post("/", authenticateToken, ctrl.crear);
router.post("/validar", authenticateToken, ctrl.validar);
router.put("/:id", authenticateToken, ctrl.actualizar);
router.delete("/:id", authenticateToken, ctrl.eliminar);

module.exports = router;