
ALTER PROCEDURE [dbo].[ObtieneEstadoDeCuentaTCM]
	@OutResultCode INT OUTPUT
	, @InIdTCM INT

AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY 
	
	--este SP es sumamente simple, tan solo hay que hacer un select a [dbo].[EstadoDeCuenta]
	--con base en el TCM que entró


	SET @OutResultCode = 0;  
	
	SELECT @OutResultCode as OutResultCode; 

	SELECT EC.FechaInicio 
		   , EC.PagoMinimoMesAnterior
		   , EC.PagoDeContado
		   , EC.InteresesCorrientes 
		   , EC.InteresesMoratorios
		   , EC.CantidadOperacionesATM
		   , EC.CantidadOperacionesVentana
		   , EC.Id 
	FROM [dbo].[EstadoDeCuenta] EC
	WHERE EC.IdTCM = @InIdTCM;


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
END