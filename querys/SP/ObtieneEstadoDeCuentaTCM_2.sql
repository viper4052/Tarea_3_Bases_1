CREATE PROCEDURE [dbo].[ObtieneEstadoDeCuentaTCM_2]
	@OutTipoUsuario INT OUTPUT
	, @InUsername VARCHAR(128)

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @IdABuscar INT;

    SET @OutTipoUsuario = 0;
	SET @OutTipoUsuario = (SELECT IdTipoDeUsuario 
						   FROM [dbo].[Usuarios]
						   WHERE Nombre = @InUsername)

	SET @IdABuscar = (SELECT Id
					  FROM [dbo].[Usuarios]
					  WHERE Nombre = @InUsername)
    
    SET @IdTCM = (SELECT IdTarjeta 
			      FROM dbo.VistaTCM 
			      WHERE IdTarjetaHabiente = @IdABuscar)


	SELECT @OutTipoUsuario AS OutTipoUsuario;        
        SELECT FechaFin,
			   PagoMinimoMesAnterior,
			   PagoDeContado,
			   InteresesCorrientes,
			   InteresesMoratorios,
			   CantidadOperacionesATM,
			   CantidadOperacionesVentana
		FROM dbo.VistaEstadoDeCuenta
		WHERE Id = @IdEstadoDeCuenta
        END
    SET NOCOUNT OFF;
END