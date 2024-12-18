USE [tarea3BD]
GO
/****** Object:  StoredProcedure [dbo].[DelegarTipoRN]    Script Date: 7/11/2024 19:43:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DelegarTipoRN]
    @OutResulTCode INT OUTPUT
    , @Id INT
    , @TipoRN VARCHAR(64) 
    , @Valor VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 2;

        IF @TipoRN = 'Porcentaje'
        BEGIN
            INSERT INTO [dbo].[RNTasa] (IdReglaNegocio, Valor) 
            VALUES (@Id, CONVERT(REAL, @Valor));
        END
        ELSE IF @TipoRN = 'Cantidad de Dias'
        BEGIN
            INSERT INTO [dbo].[RNQDias] (IdReglaNegocio, Valor) 
            VALUES (@Id, CONVERT(INT, @Valor));
        END
        ELSE IF @TipoRN = 'Cantidad de Operaciones'
        BEGIN
            INSERT INTO [dbo].[RNQOperaciones] (IdReglaNegocio, Valor) 
            VALUES (@Id, CONVERT(INT, @Valor));
        END
        ELSE IF @TipoRN = 'Monto Monetario'
        BEGIN
            INSERT INTO [dbo].[RNMonto] (IdReglaNegocio, Valor) 
            VALUES (@Id, CONVERT(MONEY, @Valor));
        END
        ELSE IF @TipoRN = 'Cantidad de Meses de Financiamiento'
        BEGIN
            INSERT INTO [dbo].[RNQMeses] (IdReglaNegocio, Valor) 
            VALUES (@Id, CONVERT(INT, @Valor));
        END
		ELSE IF @TipoRN = 'Cantidad de Años'
        BEGIN
            INSERT INTO [dbo].[RNQAños] (IdReglaNegocio, Valor) 
            VALUES (@Id, CONVERT(INT, @Valor));
        END
		SET @OutResulTCode = 1;

    END TRY
    BEGIN CATCH


        SET @OutResulTCode = 50008;


    END CATCH;

    SET NOCOUNT OFF;
END;


SET ANSI_NULLS OFF
