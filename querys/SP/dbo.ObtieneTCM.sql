CREATE PROCEDURE [dbo].[ObtieneTCM]
	@OutResultCode INT OUTPUT
	, @InUsername VARCHAR(128) 
	, @VarTipoUsuario INT
AS
BEGIN
	SET NOCOUNT ON;
	SET @OutResultCode = 0;
	SELECT @OutResultCode as OutResultCode
	
	SET @VarTipoUsuario = (SELECT IdTipoDeUsuario 
						   FROM [dbo].[Usuarios]
						   WHERE Nombre = @InUsername)
	
	-- Si es admin entonces
	IF @VarTipoUsuario = 1
		--SELECT * FROM dbo.VistaTCM M -- falta ver si se puede mostrar toda columna en todo caso
		SELECT IdTarjetaHabiente, SaldoActual 
		FROM dbo.VistaTCM M
		FULL JOIN dbo.VistaTCA A
		ON M.IdTarjetaHabiente = A.IdTarjetaHabiente -- no se si esta afirmacion es correcta
	-- Si es usuario regular
	ELSE IF @VarTipoUsuario = 2
		SELECT * FROM dbo.VistaTCM M
		INNER JOIN dbo.VistaTCA A
		ON M.IdTarjetaHabiente = A.IdTarjetaHabiente

	SET NOCOUNT OFF;
END
RETURN 0