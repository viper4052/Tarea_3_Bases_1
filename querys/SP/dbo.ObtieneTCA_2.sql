CREATE PROCEDURE [dbo].[ObtieneTCA_2]
	@OutTipoUsuario INT OUTPUT
	, @IdTCA INT OUTPUT
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


	SELECT @OutTipoUsuario AS OutTipoUsuario;
	

	
	-- Si es admin entonces
	IF (@OutTipoUsuario = 1)
		BEGIN
			--SELECT * FROM [dbo].[VistaTCM]
			SELECT * FROM [dbo].[VistaTCA]
		END

	-- Si es usuario regular entonces
	ELSE
		BEGIN
			SET @IdTCA = (SELECT IdTarjeta 
						  FROM dbo.VistaTCA 
						  WHERE IdTarjetaHabiente = @IdABuscar)
			SELECT Numero
				   , EsValida
				   , FechaVencimiento
			FROM dbo.VistaTF
			WHERE IdTarjeta = @IdTCA
			SELECT @IdTCA AS IdTCA;
		END
	
	SET NOCOUNT OFF;
END
RETURN 0