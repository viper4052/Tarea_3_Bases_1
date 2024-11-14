CREATE PROCEDURE [dbo].[ObtieneTCM]
	@OutTipoUsuario INT OUTPUT
	, @InUsername VARCHAR(128)

AS
BEGIN
	SET NOCOUNT ON;
	SET @OutTipoUsuario = 0;
	SELECT @OutTipoUsuario AS OutTipoUsuario;

	SET @OutTipoUsuario = (SELECT IdTipoDeUsuario 
						   FROM [dbo].[Usuarios]
						   WHERE Nombre = @InUsername)
	
	-- Si es admin entonces
	IF (@OutTipoUsuario = 1)
		BEGIN
			SELECT * FROM [dbo].[VistaTCM]
			SELECT * FROM [dbo].[VistaTCA]
		END
	-- Si es usuario regular entonces
	ELSE
		BEGIN
			SELECT * FROM dbo.VistaTCM M
			INNER JOIN dbo.VistaTCA A
			ON M.IdTarjetaHabiente = A.IdTarjetaHabiente
		END
	SET NOCOUNT OFF;
END
RETURN 0