ALTER VIEW MovsTCA AS
SELECT TCA.FechaMovimiento
	   , TM.Nombre
	   , M.Descripcion
	   , M.Referencia
	   , M.Monto
	   , M.NuevoSaldo
	   , M.IdEstadoDeCuenta
	   , TCA.IdTarjetaCreditoAdicional
FROM dbo.MovimientosTCA TCA
INNER JOIN dbo.Movimientos M ON M.Id = TCA.IdMovimiento
INNER JOIN dbo.TiposDeMovimiento TM ON TM.Id = M.IdTipoDeMovimiento;

