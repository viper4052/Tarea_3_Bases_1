USE [tarea3BD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    Se encarga de crear una nuev TCA
	crea tambien un nuevo TC asociado a ella junto con su primer estado de cuenta adicional
--  Descripcion de parametros: 
--  @outResultCode: codigo de resultado de ejecucion. 0 Corrio sin errores, 
valores que se insertaran
--  @InCodigoTCA
--  @InCodigoTCM
--  @InTarjetaHabiente
--  @InFecha
*/

CREATE PROCEDURE [dbo].[CrearTCA]
    @OutResulTCode INT OUTPUT
    , @InCodigoTCA INT
    , @InCodigoTCM INT
    , @InTarjetaHabiente VARCHAR(16)
	, @InFecha DATE 
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;
        -- Variables de inserción 

        DECLARE @IdTarjeta INT
				, @IdTarjetaHabiente INT
				, @IdTCM INT
				, @FechaDeCierre DATE
				, @IdReglaDeNegocio INT
				, @QDias INT;

		
    

		--preprocesamos el tipo id del TH
		SELECT @IdTarjetaHabiente = T.Id
		FROM dbo.TarjetaHabiente T
		WHERE T.ValorDocumentoIdentidad = @InTarjetaHabiente

		--Preprocesamos el Id de la TCM 
		SELECT @IdTCM = TC.Id
		FROM dbo.TarjetaCredito TC
		WHERE TC.Codigo = @InCodigoTCM;
	

		--preprocesamos Fecha de cierre
		--como ya habiamos empezado el estado de cuenta de la TCM
		--Tan solo copiamos la misma fecha
		SET @FechaDeCierre = (SELECT EC.FechaInicio
							  FROM dbo.EstadoDeCuenta EC
							  WHERE EC.IdTCM = @IdTCM
							  AND EC.FechaInicio = @InFecha);

		

        BEGIN TRANSACTION
        INSERT INTO [dbo].[TarjetaCredito]
        (
			FechaCreacion
			, Codigo
        )
        VALUES
        (
            @InFecha
			, @InCodigoTCA
        )
        
        SET @IdTarjeta = SCOPE_IDENTITY();



        INSERT INTO [dbo].[TarjetaCreditoAdicional]
        (
			IdTarjeta
			, IdTarjetaHabiente
			, IdTCM
        )
        VALUES
        (
            @IdTarjeta
            , @IdTarjetaHabiente
            , @IdTCM
        )

		
		--Ya que creamos las TCA, generemos su primer inicio de estado de cuenta adicional

		INSERT INTO [dbo].[EstadoDeCuentaAdicional]
        (
            FechaInicio
			, FechaFin
			, CantidadOperacionesATM
			, CantidadOperacionesVentana
			, SumaDeCompras
			, CantidadDeCompras
			, SumaDeRetiros
			, CantidadDeRetiros
			, SumaDeCreditos
			, SumaDeDebitos
			, IdTCM
			, IdTCA
        )
        VALUES
        (
            @InFecha
            , @FechaDeCierre
            , 0
            , 0
            , 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, @IdTCM
			, @IdTarjeta
        )
        COMMIT TRANSACTION;
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