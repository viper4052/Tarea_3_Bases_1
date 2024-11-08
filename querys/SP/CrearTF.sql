USE [tarea3BD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    Se encarga de crear una nueva TF
--  Descripcion de parametros: 
--  @outResultCode: codigo de resultado de ejecucion. 0 Corrio sin errores, 
valores que se insertaran
--  @InCodigoTCA
--  @InCodigoTCM
--  @InTarjetaHabiente
--  @InFecha
*/

ALTER PROCEDURE [dbo].[CrearTF]
    @OutResulTCode INT OUTPUT
    , @InCodigoTCA INT
	, @InNumeroTarjeta BIGINT
	, @InCCV INT 
	, @InFechaVencimiento VARCHAR(8)
	, @InFechaHoy DATE 
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;
        -- Variables de inserción 

        DECLARE @IdTarjeta INT
				, @FechaV DATE
				, @Año VARCHAR(4)
				, @Mes VARCHAR(2)
				, @StrLenght INT;
	
		--preprocesamos la fecha de vencimiento

		SET @StrLenght = LEN(@InFechaVencimiento);
	
		SET @Año = CASE 
						WHEN @StrLenght = 6 THEN SUBSTRING(@InFechaVencimiento, 3, 6)
						WHEN @StrLenght = 7 THEN SUBSTRING(@InFechaVencimiento, 4, 7)
					END 
							 
		SET @Mes = CASE 
						WHEN @StrLenght = 6 THEN SUBSTRING(@InFechaVencimiento, 1, 1)
						WHEN @StrLenght = 7 THEN SUBSTRING(@InFechaVencimiento, 1, 2)
					END 
		

		SET @FechaV = CONVERT(DATE, CONCAT(@Año,'-','01','-',@Mes));


		--Preprocesamos el Id de la Tarjeta
		SELECT @IdTarjeta = TC.Id
		FROM [dbo].[TarjetaCredito] TC
		WHERE TC.Codigo = @InCodigoTCA;
		

        INSERT INTO [dbo].[TarjetaFisica]
        (
			IdTarjeta
			, Numero
			, CCV
			, Pin
			, FechaCreacion
			, FechaVencimiento
        )
        VALUES
        (
            @IdTarjeta
			, @InNumeroTarjeta
			, @InCCV
			, 999
			, @InFechaHoy
			, @FechaV
        )
       

    END TRY
    BEGIN CATCH
        IF(@@TRANCOUNT > 0)
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
               
    END CATCH;
    RETURN;
END;