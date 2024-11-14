
--
--  Dado un codigo de error devuelve la descripicion del mismo 
  
--  Descripcion de parametros: 

--  @outResultCode: codigo de resultado de ejecucion. 0 Corrio sin errores, 
--  @OutIntentos: retorna si se cancelo el login 
--  @InUsername: aqui el posible username del usuario con el que estamos trabajando 
--  @InPassword: aqui el posible password del usuario con el que estamos trabajando 
--  @InPostInIP: aqui el IP de donde se realizo la solicitud 
--  @InPostTime: aqui el momento en el que se hizo la consulta 


CREATE PROCEDURE [dbo].[Login]
    @OutResulTCode INT OUTPUT
	, @InUsername VARCHAR(128)
	, @InPassword VARCHAR(128)
	, @InPostInIP VARCHAR(128)
	, @InPostTime DATETIME 


AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY 


	SET @OutResulTCode = 0;
	DECLARE @TipoDeEvento VARCHAR(128)
			, @Descripcion VARCHAR(128)
			, @Intento INT
			, @IdUser INT 
			, @IdEvento INT
	

		
    --Primero por si acaso revisaremos si el codigo existe
	IF NOT EXISTS
	(
		SELECT Nombre FROM dbo.Usuarios
		WHERE Nombre = @InUsername
	)
	BEGIN 
		SET @OutResulTCode = 50001;
		SET @TipoDeEvento = 'Login No exitoso';
		SET @InUsername = 'LOGINFALLIDO';
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
			SET @TipoDeEvento = 'Login No exitoso'
		END 
		ELSE 
		BEGIN 
			SET @TipoDeEvento = 'Login Exitoso'
			SET @Descripcion = ' ';
		END 
		
	

	--Ya que @InUsername de fijo existe y @TipoDeEvento tambien
	--saquemos sus Ids 
	SELECT @IdUser = Id FROM dbo.Usuarios
	WHERE @InUsername = Nombre; --esto nos va a dar el id usuario
									 -- con el que estamos trabajando
						   
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