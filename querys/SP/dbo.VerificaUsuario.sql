CREATE PROCEDURE [dbo].[VerificaUsuario]
	@TipoDeUsuario INT OUTPUT
	, @OutResultCode INT
	, @InUsername VARCHAR(128)
	, @IdUser INT 
	
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

	SET @OutResultCode = 0; 

	IF NOT EXISTS
	(
		SELECT Nombre FROM [dbo].[Usuarios]
		WHERE Nombre = @InUsername
	)
	SELECT @IdUser = Id FROM [dbo].[Usuarios]
	WHERE @InUsername = Nombre;
	
	SET @TipoDeUsuario = (SELECT IdTipoDeUsuario 
						  FROM dbo.Usuarios 
						  WHERE Nombre = @InUsername);
	
	RETURN @TipoDeUsuario

	END TRY
	BEGIN CATCH 

	INSERT INTO dbo.DBError VALUES 
		(
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );
		SET @OutResulTCode = 50008;
		

	END CATCH 
    SET NOCOUNT OFF;
END;