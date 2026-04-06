class TarjetaClienteModel {
  constructor(data = {}) {
    this.tarjetaClienteId = data.TARJETA_CLIENTE_ID ?? data.tarjetaClienteId ?? null;
    this.cliId = data.CLI_ID ?? data.cliId ?? null;
    this.titular = data.TITULAR ?? data.titular ?? '';
    this.ultimos4 = data.ULTIMOS_4 ?? data.ultimos4 ?? '';
    this.marca = data.MARCA ?? data.marca ?? '';
    this.mesVencimiento = data.MES_VENCIMIENTO ?? data.mesVencimiento ?? null;
    this.anioVencimiento = data.ANIO_VENCIMIENTO ?? data.anioVencimiento ?? null;
    this.aliasTarjeta = data.ALIAS_TARJETA ?? data.aliasTarjeta ?? null;
    this.predeterminada = data.PREDETERMINADA ?? data.predeterminada ?? 0;
    this.createdAt = data.CREATED_AT ?? data.createdAt ?? null;
    this.updatedAt = data.UPDATED_AT ?? data.updatedAt ?? null;
    this.estado = data.ESTADO ?? data.estado ?? 'ACTIVO';
  }

  toJSON() {
    return {
      tarjetaClienteId: this.tarjetaClienteId,
      cliId: this.cliId,
      titular: this.titular,
      ultimos4: this.ultimos4,
      marca: this.marca,
      mesVencimiento: this.mesVencimiento,
      anioVencimiento: this.anioVencimiento,
      aliasTarjeta: this.aliasTarjeta,
      predeterminada: this.predeterminada,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      estado: this.estado,
    };
  }
}

module.exports = TarjetaClienteModel;