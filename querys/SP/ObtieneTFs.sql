USE [tarea3BD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ObtieneTFs]
	@InTipoUsuario INT 
	, @InUsername VARCHAR(128)
	, @OutResultCode INT OUTPUT 

AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY 
	SET @OutResultCode = 0; 

	DECLARE @IdTCM INT
			, @IdTH INT ;

	DECLARE @TarjetasFisicas TABLE 
	(
		Numero BIGINT NOT NULL
		, Estado VARCHAR(16) NOT NULL 
		, FechaV DATE NOT NULL 
		, TipoDeCuenta VARCHAR(3) 
		, IdTarjeta INT NOT NULL 
	)	

	--esta parte solo aplica para los tarjeta habientes
	-- osea los id 2
	IF(@InTipoUsuario = 2) 
	BEGIN 

	--primero extraemos su id de TarjetaHabiente 
	SELECT @IdTH = T.Id
	FROM dbo.Usuarios U 
	INNER JOIN dbo.TarjetaHabiente T ON T.IdUsuario = U.Id 
	WHERE U.Nombre = @InUsername; 


	--ahora insertemos las posibles TCA 
	INSERT INTO @TarjetasFisicas
	(
		Numero
		, Estado
		, FechaV
		, TipoDeCuenta
		, IdTarjeta
	)
	SELECT  
		TF.Numero,   
		(CASE 
			WHEN TF.EsValida = 1 THEN 'Valida'
			ELSE 'Cancelada'
		  END)
		, TF.FechaVencimiento
		, 'TCA'
		, TF.IdTarjeta
	FROM dbo.TarjetaFisica TF
	INNER JOIN dbo.TarjetaCreditoAdicional TCA ON TCA.IdTarjetaHabiente = @IdTH
	WHERE TF.IdTarjeta = TCA.IdTarjeta; 

	--ahora los posibles TCMs 


	INSERT INTO @TarjetasFisicas
	(
		Numero
		, Estado
		, FechaV
		, TipoDeCuenta
		, IdTarjeta
	)
	SELECT  
		TF.Numero,   
		(CASE 
			WHEN TF.EsValida = 1 THEN 'Valida'
			ELSE 'Cancelada'
		  END)
		, TF.FechaVencimiento
		, 'TCM'
		, TF.IdTarjeta
	FROM dbo.TarjetaFisica TF
	INNER JOIN dbo.TarjetaCreditoMaestra TCM ON TCM.IdTarjetaHabiente = @IdTH
	WHERE TF.IdTarjeta = TCM.IdTarjeta; 

	END
	ELSE 
	BEGIN 
	--Ahora bien, si es admin le metemos todas 

	--ahora los posibles TCMs 

	INSERT INTO @TarjetasFisicas
	(
		Numero
		, Estado
		, FechaV
		, TipoDeCuenta
		, IdTarjeta
	)
	SELECT  
		TF.Numero,   
		(CASE 
			WHEN TF.EsValida = 1 THEN 'Valida'
			ELSE 'Cancelada'
		  END)
		, TF.FechaVencimiento
		, 'TCM'
		, TF.IdTarjeta
	FROM dbo.TarjetaFisica TF
	INNER JOIN dbo.TarjetaCreditoMaestra TCM ON TF.IdTarjeta = TCM.IdTarjeta; 


	--ahora insertemos las posibles TCA 
	INSERT INTO @TarjetasFisicas
	(
		Numero
		, Estado
		, FechaV
		, TipoDeCuenta
		, IdTarjeta
	)
	SELECT TF.Numero,   
		(CASE 
			WHEN TF.EsValida = 1 THEN 'Valida'
			ELSE 'Cancelada'
		  END)
		, TF.FechaVencimiento
		, 'TCA'
		, TF.IdTarjeta
	FROM dbo.TarjetaFisica TF
	INNER JOIN dbo.TarjetaCreditoAdicional TCA ON TF.IdTarjeta = TCA.IdTarjeta; 

	END 


	

	SELECT @OutResultCode as OutResultCode; 
	SELECT * FROM @TarjetasFisicas; 
		

	END TRY 
	BEGIN CATCH

	IF @@TRANCOUNT > 0 
	BEGIN 
	ROLLBACK; 
	END; 

	SET @OutResultCode = 50008; 
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

	SELECT @OutResultCode; 
	
	END CATCH; 
	
	SET NOCOUNT OFF;
END; 