USE [tarea3BD]
GO
/****** Object:  StoredProcedure [dbo].[ObtieneEstadoDeCuentaTCM]    Script Date: 18/11/2024 16:16:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMovimientosTCM]
	@OutResultCode INT OUTPUT
	, @InIdEC INT

AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY 
	
	--este SP es sumamente simple, tan solo hay que hacer un select a [dbo].[MovsTCM]
	--con base en el Id de EC que entró


	SET @OutResultCode = 0;  
	
	SELECT @OutResultCode as OutResultCode; 

	SELECT M.[FechaMovimiento]
		   , M.[Nombre]
		   , M.[Descripcion] 
		   , M.[Referencia]
		   , M.[Monto]
		   , M.[NuevoSaldo]
	FROM [dbo].[MovsTCM] M
	WHERE M.IdEstadoDeCuenta = @InIdEC;


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