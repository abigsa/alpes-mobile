const router = require("express").Router();
const ctrl = require("../controllers/orden_venta_detalle.controller");
router.get("/", ctrl.listar);
router.get("/buscar", ctrl.buscar);
router.get("/:id", ctrl.obtener);
router.post("/", ctrl.crear);
router.put("/:id", ctrl.actualizar);
router.delete("/:id", ctrl.eliminar);
module.exports = router;
