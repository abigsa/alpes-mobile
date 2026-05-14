const router = require("express").Router();
const ctrl = require("../controllers/cargo.controller");
const { authenticateToken } = require('../middleware/auth.middleware');
router.get("/", authenticateToken, ctrl.listar);
router.get("/:id", authenticateToken, ctrl.obtener);
router.post("/", authenticateToken, ctrl.crear);
router.put("/:id", authenticateToken, ctrl.actualizar);
router.delete("/:id", authenticateToken, ctrl.eliminar);
module.exports = router;
