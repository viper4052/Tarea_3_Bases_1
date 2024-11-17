ALTER PROCEDURE [dbo].[ObtieneEstadoDeCuentaTCA]
	@OutResultCode INT OUTPUT
	, @InIdTCA INT

AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY 
	
	--este SP es sumamente simple, tan solo hay que hacer un select a [dbo].[EstadoDeCuenta]
	--con base en el TCA que entró


	SET @OutResultCode = 0;  
	
	SELECT @OutResultCode as OutResultCode; 

	SELECT EC.FechaInicio 
		   , EC.CantidadOperacionesATM
		   , EC.CantidadOperacionesVentana
		   , EC.CantidadDeCompras
		   , EC.SumaDeCompras
		   , EC.CantidadDeRetiros
		   , EC.SumaDeRetiros
		   , EC.Id	
	FROM [dbo].EstadoDeCuentaAdicional EC 
	WHERE EC.IdTCA = @InIdTCA;


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