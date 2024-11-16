CREATE PROCEDURE [dbo].[ObtieneEstadoDeCuenta]
	@OutResultCode INT OUTPUT
	, @InUsername VARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;
	SET @OutResultCode = 0;

	DECLARE @IdTCM INT
			, @IdABuscar INT;

	SET @IdABuscar = (SELECT Id
					  FROM [dbo].[Usuarios]
					  WHERE Nombre = @InUsername)
					  
	SET @IdTCM = (SELECT IdTarjeta 
			  	  FROM dbo.VistaTCM 
			  	  WHERE IdTarjetaHabiente = @IdABuscar)

	SELECT @OutResultCode AS OutResultCode;

	BEGIN
	SELECT Fecha,
		   Descripcion,
		   Referencia,
		   Monto,
		   NuevoSaldo
	FROM dbo.Movimientos
	WHERE IdTarjetaCreditoMaestra = @IdTCM
	END

	SET NOCOUNT OFF;
END
RETURN 0
