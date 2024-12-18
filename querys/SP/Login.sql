USE [tarea3BD]
GO
/****** Object:  StoredProcedure [dbo].[Login]    Script Date: 17/11/2024 14:29:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--
--  Dado un codigo de error devuelve la descripicion del mismo 
  
--  Descripcion de parametros: 

--  @outResultCode: codigo de resultado de ejecucion. 0 Corrio sin errores, 
--  @OutIntentos: retorna si se cancelo el login 
--  @InUsername: aqui el posible username del usuario con el que estamos trabajando 
--  @InPassword: aqui el posible password del usuario con el que estamos trabajando 


ALTER PROCEDURE [dbo].[Login]
    @OutResulTCode INT OUTPUT
	, @InUsername VARCHAR(128)
	, @InPassword VARCHAR(128)
	, @OutTipoUsuario INT OUTPUT -- retorna de una vez el tipo de usuario


AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY 

	SET @OutResulTCode = 0;
	
	DECLARE @IdUser INT 
	

		
    --Primero por si acaso revisaremos si el codigo existe
	IF NOT EXISTS
	(
		SELECT Nombre FROM dbo.Usuarios
		WHERE Nombre = @InUsername
	)
	BEGIN 
		SET @OutResulTCode = 50001;
	END 
	-- Si el usuario existe ahora ver si la contrasenna corresponde
	ELSE
		IF NOT EXISTS
		(
			SELECT Nombre FROM dbo.Usuarios
			WHERE Nombre = @InUsername AND Contraseña = @InPassword
		)
		BEGIN 
			SET @OutResulTCode = 50002;
		END 
		

	--Ya que @InUsername de fijo existe 
	--saquemos sus tipo de usuario 

	SELECT @OutTipoUsuario = IdTipoDeUsuario 
	FROM dbo.Usuarios 
	WHERE Nombre = @InUsername;
	
						   
	END TRY 

	BEGIN CATCH 

	IF @@TRANCOUNT > 0 
	BEGIN 
	ROLLBACK; 
	END; 


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