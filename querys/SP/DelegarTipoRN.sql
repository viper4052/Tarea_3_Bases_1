USE [tarea3BD]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DelegarTipoRN]
	@OutResulTCode INT OUTPUT
	, @Id INT
	, @TipoRN VARCHAR(32) 
	, @Valor VARCHAR(32)

	AS
	BEGIN

	SET NOCOUNT ON;
    BEGIN TRY


	SET @OutResulTCode = 0;

	IF @TipoRN = 'Porcentaje'
	BEGIN
		INSERT INTO [dbo].[RNTasa] (IdReglaNegocio, Valor) VALUES (@Id,CONVERT(REAL,@Valor));
	END
	ELSE IF @TipoRN = 'Cantidad de Dias'
	BEGIN
		INSERT INTO [dbo].[RNQDias] (IdReglaNegocio, Valor) VALUES (@Id,CONVERT(INT,@Valor));
	END
	ELSE IF @TipoRN = 'Cantidad de Operaciones'
	BEGIN
		INSERT INTO [dbo].[RNQOperaciones](IdReglaNegocio, Valor) VALUES (@Id,CONVERT(INT,@Valor));
	END
	ELSE IF @TipoRN = 'Monto Monetario'
	BEGIN
		INSERT INTO [dbo].[RNMonto](IdReglaNegocio, Valor) VALUES (@Id,CONVERT(MONEY,@Valor));
	END



	END TRY
	BEGIN CATCH

		INSERT INTO [dbo].[DBError] VALUES 
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
		
				
	END CATCH;
	
	SET NOCOUNT OFF;
END;


SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO