CREATE VIEW MovsTCM AS
SELECT TCM.FechaMovimiento
	   , TM.Nombre
	   , M.Descripcion
	   , M.Referencia
	   , M.Monto
	   , M.NuevoSaldo
	   , M.IdEstadoDeCuenta
	   , M.IdTarjetaCreditoMaestra
FROM dbo.MovimientosTCM TCM
INNER JOIN dbo.Movimientos M ON M.Id = TCM.IdMovimiento
INNER JOIN dbo.TiposDeMovimiento TM ON TM.Id = M.IdTipoDeMovimiento;

