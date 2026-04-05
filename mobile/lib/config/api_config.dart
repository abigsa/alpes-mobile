class ApiConfig {
  // Cambia esta URL cuando despliegues el backend
  static const String baseUrl = 'http://192.168.3.127:3000/api';

  // Endpoints
  static const String login           = '/usuarios/login';
  static const String registro        = '/usuarios/registro';

  static const String productos       = '/productos';
  static const String categorias      = '/categoria';
  static const String carrito         = '/carrito';
  static const String carritoDetalle  = '/carrito_detalle';
  static const String ordenVenta      = '/ordenes-venta';
  static const String ordenVentaDet   = '/ordenes-venta-detalle';
  static const String pago            = '/pagos';
  static const String metodoPago      = '/metodos-pago';
  static const String envio           = '/envios';
  static const String estadoEnvio     = '/estados-envio';
  static const String seguimiento     = '/seguimiento-envio';
  static const String listaDeseseos   = '/listas-deseos';
  static const String resenas         = '/resenas-comentarios';
  static const String cliente         = '/clientes';
  static const String factura         = '/facturas';
  static const String cupon           = '/cupones';
  static const String promocion       = '/promociones';
  static const String faq             = '/faqs';
  static const String historialCompra = '/historial-compra';
  static const String precioHistorico = '/precios-historico';

  // Admin
  static const String empleados       = '/empleados';
  static const String departamentos   = '/departamentos';
  static const String cargos          = '/cargos';
  static const String roles           = '/roles';
  static const String permisos        = '/permisos';
  static const String nomina          = '/nominas';
  static const String nominaDetalle   = '/nominas-detalle';
  static const String evaluaciones    = '/evaluaciones';
  static const String incidentes      = '/incidentes-laborales';
  static const String histLaboral     = '/historial-laboral';
  static const String expedienteEmp   = '/expedientes-empleado';

  static const String proveedores         = '/proveedores';
  static const String ordenCompra         = '/ordenes-compra';
  static const String ordenCompraDet      = '/ordenes-compra-detalle';
  static const String recepcionMaterial   = '/recepciones-material';
  static const String contratoProv        = '/contratos-proveedor';
  static const String expedienteProv      = '/expedientes-proveedor';
  static const String cuentaPagar         = '/cuentas-pagar-proveedor';
  static const String pagoProv            = '/pagos-proveedor';

  static const String inventarioProducto  = '/inventario-producto';
  static const String inventarioMP        = '/inventario-materia-prima';
  static const String materiaPrima        = '/materias-primas';
  static const String movInv              = '/movimientos-inventario';
  static const String movMP               = '/movimientos-materia-prima';

  static const String ordenProduccion     = '/ordenes-produccion';
  static const String ordenProdTarea      = '/ordenes-produccion-tareas';
  static const String planProduccion      = '/planes-produccion';
  static const String estadoProduccion    = '/estados-produccion';
  static const String consumoMP           = '/consumos-materia-prima';
  static const String produccionRes       = '/produccion-resultados';
  static const String listaMateriales     = '/listas-materiales';
  static const String listaMatDet         = '/listas-materiales-detalle';

  static const String herramientas        = '/herramientas';
  static const String mantenimiento       = '/mantenimiento-herramientas';
  static const String vehiculos           = '/vehiculos';
  static const String rutaEntrega         = '/rutas-entrega';

  static const String campanaMarketing    = '/campanas-marketing';
  static const String tipoPromocion       = '/tipos-promocion';
  static const String promocionProducto   = '/promociones-producto';
  static const String reglaPromocion      = '/reglas-promocion';
  static const String histPromocion       = '/historial-promocion';

  static const String zonaEnvio           = '/zonas-envio';
  static const String tarifaEnvio         = '/tarifas-envio';
  static const String tipoEntrega         = '/tipos-entrega';
  static const String politicaEnvio       = '/politicas-envio';
  static const String reglaEnvioGratis    = '/reglas-envio-gratis';

  static const String usuarios            = '/usuarios';
  static const String sesiones            = '/sesiones';
  static const String rolEmpleado         = '/roles-empleado';
  static const String rolPermiso          = '/roles-permiso';
  static const String condicionPago       = '/condiciones-pago';
  static const String unidadMedida        = '/unidades-medida';
  static const String estadoOrden         = '/estados-orden';
  static const String estadoOrdenCompra   = '/estados-orden-compra';
  static const String devolucion          = '/devoluciones';
  static const String controlCalidad      = '/control-calidad';
  static const String abastecimiento      = '/abastecimientos';
  static const String prefCliente         = '/preferencias-cliente';
  static const String cuotasPago          = '/cuotas-pago';
}
