const express = require('express');
const router = express.Router();
const tarjetaclientecontroller = require('../controllers/tarjetaclientecontroller');

router.post('/', tarjetaclientecontroller.crearTarjeta);
router.get('/cliente/:cliId', tarjetaclientecontroller.listarTarjetasPorCliente);
router.get('/:tarjetaClienteId', tarjetaclientecontroller.obtenerTarjetaPorId);
router.put('/:tarjetaClienteId', tarjetaclientecontroller.actualizarTarjeta);
router.delete('/:tarjetaClienteId', tarjetaclientecontroller.desactivarTarjeta);
router.patch('/:tarjetaClienteId/predeterminada', tarjetaclientecontroller.marcarPredeterminada);

module.exports = router;